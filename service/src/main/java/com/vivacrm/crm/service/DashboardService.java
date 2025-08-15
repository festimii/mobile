package com.vivacrm.crm.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Types;
import java.time.LocalDate;
import java.util.*;

/**
 * Robust caller for dbo.SP_GetDashboardData.
 *
 * Supports both:
 *  1) Result-set style procs (first row contains metric columns)
 *  2) OUT-parameter style procs (named outputs)
 *
 * Recommendation for the T-SQL proc:
 *   - Put "SET NOCOUNT ON;" at the top to avoid extra update counts breaking result-set detection.
 *   - Return either ONE result set with the expected columns OR define OUT params with the same names.
 */
@Service
public class DashboardService {

    private final JdbcTemplate sqlServerJdbc;
    private final SimpleJdbcCall spResultSet; // expects a result set
    private final SimpleJdbcCall spOutParams; // expects named OUT parameters

    public DashboardService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbcTemplate) {
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        this.sqlServerJdbc = jdbcTemplate;

        // Path A: result set mapping (first result set -> List<Map<String,Object>>)
        this.spResultSet = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .returningResultSet("#result-set-1", new ColumnMapRowMapper());

        // Path B: OUT parameters (disable metadata, declare names/types explicitly)
        this.spOutParams = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        // Adjust Types if your proc uses other SQL types
                        new org.springframework.jdbc.core.SqlOutParameter("TotalRevenue",      Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("Transactions",      Types.BIGINT),
                        new org.springframework.jdbc.core.SqlOutParameter("AvgBasketSize",     Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductCode",    Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductName",    Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("ReturnsToday",      Types.INTEGER),
                        new org.springframework.jdbc.core.SqlOutParameter("LowInventoryCount", Types.INTEGER)
                );
    }

    /**
     * Calls the SP for today's metrics. If your proc needs a date parameter, switch to getMetrics(LocalDate).
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getMetrics() {
        return getMetrics(LocalDate.now());
    }

    /**
     * Calls the SP with a business date parameter (if your proc accepts one).
     * If your proc has no input params, the param map will be ignored by SQL Server.
     */
    @Transactional(readOnly = true)
    public List<Map<String, Object>> getMetrics(LocalDate date) {
        MapSqlParameterSource in = new MapSqlParameterSource()
                // If the proc expects a date parameter, name it accordingly (e.g., @p_Date)
                // .addValue("p_Date", java.sql.Date.valueOf(date))
                ;

        // --- Try result-set mode first ---
        try {
            Map<String, Object> out = spResultSet.execute(in);
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rows =
                    (List<Map<String, Object>>) out.getOrDefault("#result-set-1", Collections.emptyList());

            if (!rows.isEmpty()) {
                Map<String, Object> row = rows.get(0);
                return buildPayloadFromMap(row);
            }
        } catch (Exception ignored) {
            // Fall through to OUT-parameter mode
        }

        // --- Fallback: OUT-parameter mode ---
        try {
            Map<String, Object> out = spOutParams.execute(in);
            return buildPayloadFromMap(out);
        } catch (Exception ex) {
            // Final fallback with zeros to keep endpoint stable
            return zeroPayload();
        }
    }

    // ---------- helpers ----------

    private static List<Map<String, Object>> buildPayloadFromMap(Map<String, Object> source) {
        return List.of(
                metric("Total Revenue",       asString(source, "TotalRevenue", "0")),
                metric("Transactions",        asString(source, "Transactions", "0")),
                metric("Avg Basket Size",     asString(source, "AvgBasketSize", "0")),
                metric("Top Product Code",    asString(source, "TopProductCode", "")),
                metric("Top Product Name",    asString(source, "TopProductName", "")),
                metric("Returns Today",       asString(source, "ReturnsToday", "0")),
                metric("Low Inventory Count", asString(source, "LowInventoryCount", "0"))
        );
    }

    private static List<Map<String, Object>> zeroPayload() {
        return List.of(
                metric("Total Revenue", "0"),
                metric("Transactions", "0"),
                metric("Avg Basket Size", "0"),
                metric("Top Product Code", ""),
                metric("Top Product Name", ""),
                metric("Returns Today", "0"),
                metric("Low Inventory Count", "0")
        );
    }

    private static Map<String, Object> metric(String title, String value) {
        Map<String, Object> m = new LinkedHashMap<>(2);
        m.put("title", title);
        m.put("value", value);
        return m;
    }

    private static String asString(Map<String, Object> map, String key, String def) {
        if (map == null) return def;
        Object v = map.get(key);
        if (v == null) return def;
        if (v instanceof BigDecimal bd) return bd.stripTrailingZeros().toPlainString();
        return String.valueOf(v);
        // Numbers/Strings/Null all normalize to String
    }
}
