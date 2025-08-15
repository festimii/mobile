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
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Types;
import java.time.LocalDate;
import java.util.*;

@Service
public class DashboardService {

    private static final BigDecimal THOUSAND = new BigDecimal("1000");
    private static final BigDecimal MILLION  = new BigDecimal("1000000");
    private static final BigDecimal BILLION  = new BigDecimal("1000000000");

    private final JdbcTemplate sqlServerJdbc;
    private final SimpleJdbcCall spResultSet; // result-set mode
    private final SimpleJdbcCall spOutParams; // OUT-parameter mode (metrics fallback)


    private static final DateTimeFormatter DOW_FMT = DateTimeFormatter.ofPattern("EEE", Locale.ENGLISH);
    private static final DateTimeFormatter[] DATE_PARSERS = new DateTimeFormatter[] {
            DateTimeFormatter.ISO_LOCAL_DATE,                    // 2025-08-09
            DateTimeFormatter.ofPattern("dd.MM.yyyy"),           // 09.08.2025
            DateTimeFormatter.ofPattern("dd/MM/yyyy"),           // 09/08/2025
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),           // 08/09/2025
            DateTimeFormatter.ofPattern("yyyyMMdd")              // 20250809
    };
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

        // Build top metrics with compact formatting
        List<Metric> metrics = List.of(
                new Metric("Total Revenue",       compactFromMap(metricsRow, "TotalRevenue")),
                new Metric("Transactions",        compactFromMap(metricsRow, "Transactions")),
                new Metric("Avg Basket Size",     compactFromMap(metricsRow, "AvgBasketSize")),
                new Metric("Top Product Code",    asString(metricsRow, "TopProductCode", "")),
                new Metric("Top Product Name",    asString(metricsRow, "TopProductName", "")),
                new Metric("Returns Today",       compactFromMap(metricsRow, "ReturnsToday")),
                new Metric("Low Inventory Count", compactFromMap(metricsRow, "LowInventoryCount"))
        );

// ⬇️ Use day-of-week labels for daily series
        List<Point> dailySeries  = mapDailyPointsWithDOW(rs2, "Label", "Amount"); // Mon, Tue, ...
        List<Point> hourlySeries = mapPoints(rs3, "HourLabel", "Amount");
        List<StoreCompare> storeComparison = mapStores(rs4, "Store", "LastYear", "ThisYear");
        return new DashboardPayload(metrics, dailySeries, hourlySeries, storeComparison);
    }
    private static List<Point> mapDailyPointsWithDOW(List<Map<String, Object>> rows, String dateCol, String amtCol) {
        List<Point> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String raw = String.valueOf(r.getOrDefault(dateCol, ""));
            String dow = toDayOfWeek(raw);               // "Mon", "Tue", ...
            BigDecimal amount = toDecimal(r.get(amtCol));
            out.add(new Point(dow, amount, formatCompact(amount)));
        }
        return out;
    }
    private static String toDayOfWeek(String dateText) {
        if (dateText == null || dateText.isBlank()) return "";
        for (DateTimeFormatter fmt : DATE_PARSERS) {
            try {
                LocalDate d = LocalDate.parse(dateText.trim(), fmt);
                return DOW_FMT.format(d);
            } catch (DateTimeParseException ignore) {
                // try next format
            }
        }
        return dateText; // fallback: return original if not a parsable date
    }
    // ---------- helpers ----------

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> getList(Map<String, Object> out, String primaryKey, String altKey) {
        Object v = out.get(primaryKey);
        if (v instanceof List<?> l && !l.isEmpty() && l.get(0) instanceof Map) return (List<Map<String, Object>>) v;
        v = out.get(altKey);
        if (v instanceof List<?> l2 && !l2.isEmpty() && l2.get(0) instanceof Map) return (List<Map<String, Object>>) v;
        return Collections.emptyList();
    }

    private static List<Point> mapPoints(List<Map<String, Object>> rows, String labelCol, String amtCol) {
        List<Point> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String label = String.valueOf(r.getOrDefault(labelCol, ""));
            BigDecimal amount = toDecimal(r.get(amtCol));
            out.add(new Point(label, amount, formatCompact(amount)));
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
            out.add(new StoreCompare(
                    store,
                    lastYear, thisYear,
                    formatCompact(lastYear), formatCompact(thisYear)
            ));
        }
        return out;
    }

    private static BigDecimal toDecimal(Object v) {
        if (v == null) return BigDecimal.ZERO;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try { return new BigDecimal(String.valueOf(v).trim()); }
        catch (Exception e) { return BigDecimal.ZERO; }
    }

    private static String asString(Map<String, Object> map, String key, String def) {
        if (map == null) return def;
        Object v = map.get(key);
        if (v == null) return def;
        if (v instanceof BigDecimal bd) return bd.stripTrailingZeros().toPlainString();
        return String.valueOf(v);
    }

    private static String compactFromMap(Map<String, Object> map, String key) {
        return formatCompact(toDecimal(map != null ? map.get(key) : null));
    }

    /** Format with suffixes: K (thousand), M (million), B (billion); 2-dp, trimmed. */
    private static String formatCompact(BigDecimal n) {
        boolean neg = n.signum() < 0;
        BigDecimal abs = n.abs();
        String suffix;
        BigDecimal val;

        if (abs.compareTo(BILLION) >= 0) {
            val = abs.divide(BILLION, 2, RoundingMode.HALF_UP);
            suffix = "B";
        } else if (abs.compareTo(MILLION) >= 0) {
            val = abs.divide(MILLION, 2, RoundingMode.HALF_UP);
            suffix = "M";
        } else if (abs.compareTo(THOUSAND) >= 0) {
            val = abs.divide(THOUSAND, 2, RoundingMode.HALF_UP);
            suffix = "K";
        } else {
            val = abs.setScale(2, RoundingMode.HALF_UP);
            suffix = "";
        }

        String core = stripZeros(val);
        return (neg ? "-" : "") + core + suffix;
    }

    private static String stripZeros(BigDecimal bd) {
        String s = bd.stripTrailingZeros().toPlainString();
        // ensure "0" instead of "-0"
        return s.equals("-0") ? "0" : s;
    }
}
