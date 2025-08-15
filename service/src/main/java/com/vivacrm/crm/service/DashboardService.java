package com.vivacrm.crm.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.ResultSetMetaData;
import java.util.*;

/**
 * Calls SQL Server stored procedure dbo.SP_GetDashboardData and maps the first row
 * of its result set into the required List<Map<title,value>> payload.
 *
 * Assumptions (adjust if different):
 *  - The proc returns a single result set with at least these columns:
 *    TotalRevenue, Transactions, AvgBasketSize, TopProductCode, TopProductName,
 *    ReturnsToday, LowInventoryCount
 *
 * If your proc returns OUT parameters instead of a result set, see the commented
 * "OUT parameters" block below.
 */
@Service
public class DashboardService {

    private final JdbcTemplate sqlServerJdbc;
    private final SimpleJdbcCall spGetDashboardData;

    public DashboardService(@Qualifier("sqlServerJdbcTemplate") JdbcTemplate jdbcTemplate) {
        // Make column-name lookup case-insensitive for Map results
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        this.sqlServerJdbc = jdbcTemplate;

        // Configure once and reuse (thread-safe after compilation)
        this.spGetDashboardData = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                // Expect a result set; map each row as a Map<String,Object>
                .returningResultSet("rs", new ColumnMapRowMapper());
        // If your driver/proc exposes a different key, change "rs" accordingly.
        // For many SQL Server procs, SimpleJdbcCall uses the name you provide here.
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getMetrics() {
        try {
            final Map<String, Object> out = spGetDashboardData.execute();

            // Try common keys for a single result set
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rows = (List<Map<String, Object>>) (
                    out.containsKey("rs") ? out.get("rs") :
                            out.containsKey("#result-set-1") ? out.get("#result-set-1") :
                                    Collections.emptyList()
            );

            final Map<String, Object> row = rows.isEmpty() ? Collections.emptyMap() : rows.get(0);

            return List.of(
                    metric("Total Revenue",      asString(row, "TotalRevenue", "0")),
                    metric("Transactions",       asString(row, "Transactions", "0")),
                    metric("Avg Basket Size",    asString(row, "AvgBasketSize", "0")),
                    metric("Top Product Code",   asString(row, "TopProductCode", "")),
                    metric("Top Product Name",   asString(row, "TopProductName", "")),
                    metric("Returns Today",      asString(row, "ReturnsToday", "0")),
                    metric("Low Inventory Count",asString(row, "LowInventoryCount", "0"))
            );

        } catch (Exception ex) {
            // Fallback with zeros to keep the endpoint stable
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
    }

    /*
     * --- Alternative: if the procedure returns OUT parameters (no result set) ---
     *
     * Enable this configuration instead of returningResultSet(...):
     *
     * this.spGetDashboardData = new SimpleJdbcCall(sqlServerJdbc)
     *      .withSchemaName("dbo")
     *      .withProcedureName("SP_GetDashboardData")
     *      .withoutProcedureColumnMetaDataAccess()
     *      .declareParameters(
     *          new SqlOutParameter("TotalRevenue",     Types.DECIMAL),
     *          new SqlOutParameter("Transactions",     Types.BIGINT),
     *          new SqlOutParameter("AvgBasketSize",    Types.DECIMAL),
     *          new SqlOutParameter("TopProductCode",   Types.VARCHAR),
     *          new SqlOutParameter("TopProductName",   Types.VARCHAR),
     *          new SqlOutParameter("ReturnsToday",     Types.INTEGER),
     *          new SqlOutParameter("LowInventoryCount",Types.INTEGER)
     *      );
     *
     * Then read directly from the 'out' map:
     * String totalRevenue = asString(out, "TotalRevenue", "0");
     */

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
    }
}
