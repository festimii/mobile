// src/main/java/com/vivacrm/crm/service/DashboardService.java
package com.vivacrm.crm.service;

import com.vivacrm.crm.service.dto.*;
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

@Service
public class DashboardService {

    private final JdbcTemplate sqlServerJdbc;
    private final SimpleJdbcCall spResultSet; // result-set mode
    private final SimpleJdbcCall spOutParams; // OUT-parameter mode (metrics fallback)

    public DashboardService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbcTemplate) {
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        this.sqlServerJdbc = jdbcTemplate;

        // Expect up to 4 result sets
        this.spResultSet = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .returningResultSet("#result-set-1", new ColumnMapRowMapper())
                .returningResultSet("#result-set-2", new ColumnMapRowMapper())
                .returningResultSet("#result-set-3", new ColumnMapRowMapper())
                .returningResultSet("#result-set-4", new ColumnMapRowMapper());

        // Metrics OUT-param fallback (if the proc is implemented that way)
        this.spOutParams = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new org.springframework.jdbc.core.SqlOutParameter("TotalRevenue",      Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("Transactions",      Types.BIGINT),
                        new org.springframework.jdbc.core.SqlOutParameter("AvgBasketSize",     Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductCode",    Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductName",    Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("ReturnsToday",      Types.INTEGER),
                        new org.springframework.jdbc.core.SqlOutParameter("LowInventoryCount", Types.INTEGER)
                );
    }

    @Transactional(readOnly = true)
    public DashboardPayload getMetrics() {
        return getMetrics(LocalDate.now());
    }

    @Transactional(readOnly = true)
    public DashboardPayload getMetrics(LocalDate date) {
        MapSqlParameterSource in = new MapSqlParameterSource();
        // If your proc expects a date: in.addValue("p_Date", java.sql.Date.valueOf(date));

        List<Map<String, Object>> rs1 = Collections.emptyList();
        List<Map<String, Object>> rs2 = Collections.emptyList();
        List<Map<String, Object>> rs3 = Collections.emptyList();
        List<Map<String, Object>> rs4 = Collections.emptyList();
        Map<String, Object> metricsRow = Collections.emptyMap();

        // Try multi-result-set mode first
        try {
            Map<String, Object> out = spResultSet.execute(in);
            rs1 = getList(out, "#result-set-1", "rs");           // metrics row
            rs2 = getList(out, "#result-set-2", "daily");        // Label, Amount
            rs3 = getList(out, "#result-set-3", "hourly");       // HourLabel, Amount
            rs4 = getList(out, "#result-set-4", "stores");       // Store, LastYear, ThisYear
            metricsRow = rs1.isEmpty() ? Collections.emptyMap() : rs1.get(0);
        } catch (Exception ignore) {
            // Fall back to OUT-params for metrics only
            try {
                Map<String, Object> out = spOutParams.execute(in);
                metricsRow = out;
            } catch (Exception ignoredToo) {
                metricsRow = Collections.emptyMap();
            }
        }

        // Build payload parts
        List<Metric> metrics = List.of(
                new Metric("Total Revenue",      asString(metricsRow, "TotalRevenue", "0")),
                new Metric("Transactions",       asString(metricsRow, "Transactions", "0")),
                new Metric("Avg Basket Size",    asString(metricsRow, "AvgBasketSize", "0")),
                new Metric("Top Product Code",   asString(metricsRow, "TopProductCode", "")),
                new Metric("Top Product Name",   asString(metricsRow, "TopProductName", "")),
                new Metric("Returns Today",      asString(metricsRow, "ReturnsToday", "0")),
                new Metric("Low Inventory Count",asString(metricsRow, "LowInventoryCount", "0"))
        );

        List<Point> dailySeries = mapPoints(rs2, "Label", "Amount");          // e.g., 2025-08-09 / 1681008.68
        List<Point> hourlySeries = mapPoints(rs3, "HourLabel", "Amount");     // e.g., 5h / 7.05
        List<StoreCompare> storeComparison = mapStores(rs4, "Store", "LastYear", "ThisYear"); // e.g., VFS ... / 3466.02 / 3329.39

        return new DashboardPayload(metrics, dailySeries, hourlySeries, storeComparison);
    }

    // ---------- helpers ----------

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> getList(Map<String, Object> out, String primaryKey, String altKey) {
        Object v = out.get(primaryKey);
        if (v instanceof List<?> l && !l.isEmpty() && l.get(0) instanceof Map) return (List<Map<String, Object>>) v;
        v = out.get(altKey);
        if (v instanceof List<?> l2 && !l2.isEmpty() && l2.get(0) instanceof Map) return (List<Map<String, Object>>) v;
        // Some drivers expose first set as "#result-set-1" only; others may use "RS1" etc.
        return Collections.emptyList();
    }

    private static List<Point> mapPoints(List<Map<String, Object>> rows, String labelCol, String amtCol) {
        List<Point> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String label = String.valueOf(r.getOrDefault(labelCol, ""));
            BigDecimal amount = toDecimal(r.get(amtCol));
            out.add(new Point(label, amount));
        }
        return out;
    }

    private static List<StoreCompare> mapStores(List<Map<String, Object>> rows, String storeCol,
                                                String lastYearCol, String thisYearCol) {
        List<StoreCompare> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String store = String.valueOf(r.getOrDefault(storeCol, ""));
            BigDecimal lastYear = toDecimal(r.get(lastYearCol));
            BigDecimal thisYear = toDecimal(r.get(thisYearCol));
            out.add(new StoreCompare(store, lastYear, thisYear));
        }
        return out;
    }

    private static BigDecimal toDecimal(Object v) {
        if (v == null) return BigDecimal.ZERO;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try { return new BigDecimal(String.valueOf(v)); } catch (Exception e) { return BigDecimal.ZERO; }
    }

    private static String asString(Map<String, Object> map, String key, String def) {
        if (map == null) return def;
        Object v = map.get(key);
        if (v == null) return def;
        if (v instanceof BigDecimal bd) return bd.stripTrailingZeros().toPlainString();
        return String.valueOf(v);
    }
}
