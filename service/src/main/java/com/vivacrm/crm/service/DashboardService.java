// src/main/java/com/vivacrm/crm/service/DashboardService.java
package com.vivacrm.crm.service;

import com.vivacrm.crm.service.dto.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Types;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;

@Service
public class DashboardService {

    private static final BigDecimal THOUSAND = new BigDecimal("1000");
    private static final BigDecimal MILLION  = new BigDecimal("1000000");
    private static final BigDecimal BILLION  = new BigDecimal("1000000000");
    private static final BigDecimal FOUR_HUNDRED = new BigDecimal("400");

    private static final DateTimeFormatter DOW_FMT = DateTimeFormatter.ofPattern("EEE", Locale.ENGLISH);
    private static final DateTimeFormatter[] DATE_PARSERS = new DateTimeFormatter[] {
            DateTimeFormatter.ISO_LOCAL_DATE,
            DateTimeFormatter.ofPattern("dd.MM.yyyy"),
            DateTimeFormatter.ofPattern("dd/MM/yyyy"),
            DateTimeFormatter.ofPattern("MM/dd/yyyy"),
            DateTimeFormatter.ofPattern("yyyyMMdd")
    };

    private final JdbcTemplate sqlServerJdbc;
    private final SimpleJdbcCall spResultSet; // result-set mode
    private final SimpleJdbcCall spOutParams; // OUT-parameter mode (metrics fallback)

    public DashboardService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbcTemplate) {
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        this.sqlServerJdbc = jdbcTemplate;

        this.spResultSet = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .returningResultSet("#result-set-1", new ColumnMapRowMapper())
                .returningResultSet("#result-set-2", new ColumnMapRowMapper())
                .returningResultSet("#result-set-3", new ColumnMapRowMapper())
                .returningResultSet("#result-set-4", new ColumnMapRowMapper());

        this.spOutParams = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new org.springframework.jdbc.core.SqlOutParameter("CutoffHour",            Types.INTEGER),
                        new org.springframework.jdbc.core.SqlOutParameter("TotalRevenue",          Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("Transactions",          Types.BIGINT),
                        new org.springframework.jdbc.core.SqlOutParameter("AvgBasketSize",         Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("TotalRevenuePY",        Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("TransactionsPY",        Types.BIGINT),
                        new org.springframework.jdbc.core.SqlOutParameter("AvgBasketSizePY",       Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("RevenueYesterday",      Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("RevenueVsYesterdayPct", Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("RevenueVsPYPct",        Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductCode",        Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopProductName",        Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopStoreOE",            Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopStoreName",          Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("TopStoreRevenue",       Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("ReturnsToday",          Types.INTEGER),
                        new org.springframework.jdbc.core.SqlOutParameter("ReturnsValue",          Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("ReturnsRatePct",        Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("DiscountSharePct",      Types.DECIMAL),
                        new org.springframework.jdbc.core.SqlOutParameter("PeakHour",              Types.INTEGER),
                        new org.springframework.jdbc.core.SqlOutParameter("PeakHourLabel",         Types.VARCHAR),
                        new org.springframework.jdbc.core.SqlOutParameter("LowInventoryCount",     Types.INTEGER)
                );
    }

    /** Cached read: stays cached until explicitly refreshed/evicted. */
    @Cacheable(value = "dashboard", key = "'metrics'")
    @Transactional(readOnly = true)
    public DashboardPayload getMetrics() {
        return loadMetrics(LocalDate.now());
    }

    /** Force-refresh cache and return fresh payload. */
    @CachePut(value = "dashboard", key = "'metrics'")
    @Transactional(readOnly = true)
    public DashboardPayload refreshMetrics() {
        return loadMetrics(LocalDate.now());
    }

    /** Evict cached payload (manual reset). */
    @CacheEvict(value = "dashboard", key = "'metrics'")
    public void resetMetrics() { /* no-op */ }

    /** Auto-refresh every 20 minutes. */
    @Scheduled(fixedDelay = 20 * 60 * 1000L)
    @Transactional(readOnly = true)
    public void refreshMetricsEvery20Minutes() {
        refreshMetrics();
    }

    // ----------------- internal loader -----------------
    @Transactional(readOnly = true)
    protected DashboardPayload loadMetrics(LocalDate date) {
        MapSqlParameterSource in = new MapSqlParameterSource();
        // If your proc expects a date param, add it here:
        // in.addValue("p_Date", java.sql.Date.valueOf(date));

        List<Map<String, Object>> rs1 = Collections.emptyList();
        List<Map<String, Object>> rs2 = Collections.emptyList();
        List<Map<String, Object>> rs3 = Collections.emptyList();
        List<Map<String, Object>> rs4 = Collections.emptyList();
        Map<String, Object> metricsRow = Collections.emptyMap();

        try {
            Map<String, Object> out = spResultSet.execute(in);
            rs1 = getList(out, "#result-set-1", "rs");
            rs2 = getList(out, "#result-set-2", "daily");
            rs3 = getList(out, "#result-set-3", "hourly");
            rs4 = getList(out, "#result-set-4", "stores");
            metricsRow = rs1.isEmpty() ? Collections.emptyMap() : rs1.get(0);
        } catch (Exception ignore) {
            try {
                Map<String, Object> out = spOutParams.execute(in);
                metricsRow = out;
            } catch (Exception ignoredToo) {
                metricsRow = Collections.emptyMap();
            }
        }

        // ---- grouped metrics with sub-metrics ----
        List<Metric> metrics = List.of(
                m("Total Revenue", compactFromMap(metricsRow, "TotalRevenue"), List.of(
                        m("VS Dje", compactFromMap(metricsRow, "RevenueVsYesterdayPct") + "%"),
                        m("Vs Viti Kaluar", compactFromMap(metricsRow, "RevenueVsPYPct") + "%"),
                        m("Total Viti Kaluar", compactFromMap(metricsRow, "TotalRevenuePY")),
                        m("Dje", compactFromMap(metricsRow, "RevenueYesterday")),
                        m("Top Pika", asString(metricsRow, "TopStoreName", "")),
                        m("Shitjet e Pikes", compactFromMap(metricsRow, "TopStoreRevenue")),
                        m("Total Peek", asString(metricsRow, "PeakHour", ""))
                )),

                m("Kuponat", compactFromMap(metricsRow, "Transactions"), List.of(
                        m("Vs Viti Kaluar", pctFromMap(metricsRow, "Transactions", "TransactionsPY") + "%"),
                        m("Viti Kaluar", compactFromMap(metricsRow, "TransactionsPY"))
                )),

                m("Shporta Mesatare", compactFromMap(metricsRow, "AvgBasketSize"), List.of(
                        m("Vs Viti Kaluar", pctFromMap(metricsRow, "AvgBasketSize", "AvgBasketSizePY") + "%"),
                        m("Viti Kaluar", compactFromMap(metricsRow, "AvgBasketSizePY"))
                ))
        );

        // Daily series labels as day-of-week: Mon, Tue, ...
        List<Point> dailySeries  = mapDailyPointsWithDOW(rs2, "Label", "Amount");
        List<Point> hourlySeries = mapHourlyCompressed(rs3, "HourLabel", "Amount");
        List<StoreCompare> storeComparison = mapStores(rs4, "Store", "LastYear", "ThisYear");

        return new DashboardPayload(metrics, dailySeries, hourlySeries, storeComparison);
    }

    // ----------------- helpers -----------------
    private static Metric m(String name, String value) {
        return new Metric(name, value);
    }
    private static Metric m(String name, String value, List<Metric> subs) {
        return new Metric(name, value, subs);
    }

    @SuppressWarnings("unchecked")
    private static List<Map<String, Object>> getList(Map<String, Object> out, String primaryKey, String altKey) {
        Object v = out.get(primaryKey);
        if (v instanceof List<?> l && !l.isEmpty() && l.get(0) instanceof Map)
            return (List<Map<String, Object>>) v;
        v = out.get(altKey);
        if (v instanceof List<?> l2 && !l2.isEmpty() && l2.get(0) instanceof Map)
            return (List<Map<String, Object>>) v;
        return Collections.emptyList();
    }

    private static List<Point> mapDailyPointsWithDOW(List<Map<String, Object>> rows, String dateCol, String amtCol) {
        List<Point> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String raw = String.valueOf(r.getOrDefault(dateCol, ""));
            String dow = toDayOfWeek(raw);
            BigDecimal amount = toDecimal(r.get(amtCol));
            out.add(new Point(dow, amount, formatCompact(amount)));
        }
        return out;
    }

    private static List<Point> mapHourlyCompressed(List<Map<String, Object>> rows, String labelCol, String amtCol) {
        if (rows == null || rows.isEmpty()) return List.of();

        // Normalize -> HourBin and sort by hour
        List<HourBin> bins = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            String lbl = String.valueOf(r.getOrDefault(labelCol, "")).trim();
            int hour = parseHour(lbl);
            if (hour < 0) continue; // skip unparseable labels
            BigDecimal val = toDecimal(r.get(amtCol));
            bins.add(new HourBin(hour, lbl, val));
        }
        bins.sort(Comparator.comparingInt(b -> b.hour));

        // First pass: drop zeros
        List<HourBin> nonZero = new ArrayList<>();
        for (HourBin b : bins) {
            if (b.value.compareTo(BigDecimal.ZERO) > 0) {
                nonZero.add(b);
            }
        }
        if (nonZero.isEmpty()) return List.of();

        // Second pass: merge small hours (<= 400) forward; if last, merge backward
        List<HourBin> kept = new ArrayList<>();
        for (int i = 0; i < nonZero.size(); i++) {
            HourBin cur = nonZero.get(i);

            if (cur.value.compareTo(FOUR_HUNDRED) <= 0) {
                if (i + 1 < nonZero.size()) {
                    nonZero.get(i + 1).value = nonZero.get(i + 1).value.add(cur.value);
                } else if (!kept.isEmpty()) {
                    kept.get(kept.size() - 1).value = kept.get(kept.size() - 1).value.add(cur.value);
                } else {
                    kept.add(cur); // single tiny bucket edge-case
                }
                continue; // drop current as standalone
            }

            kept.add(cur);
        }

        List<Point> out = new ArrayList<>(kept.size());
        for (HourBin b : kept) {
            out.add(new Point(b.label, b.value, formatCompact(b.value)));
        }
        return out;
    }

    private static class HourBin {
        final int hour;
        final String label;
        BigDecimal value;
        HourBin(int hour, String label, BigDecimal value) {
            this.hour = hour;
            this.label = label;
            this.value = value;
        }
    }

    private static int parseHour(String label) {
        if (label == null) return -1;
        var m = java.util.regex.Pattern.compile("(\\d{1,2})").matcher(label);
        if (m.find()) {
            int h = Integer.parseInt(m.group(1));
            return (h >= 0 && h <= 23) ? h : -1;
        }
        return -1;
    }

    private static List<StoreCompare> mapStores(List<Map<String, Object>> rows, String storeCol,
                                                String lastYearCol, String thisYearCol) {
        List<StoreCompare> out = new ArrayList<>(rows.size());
        for (Map<String, Object> r : rows) {
            String store = String.valueOf(r.getOrDefault(storeCol, "")).trim();
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

    private static String toDayOfWeek(String dateText) {
        if (dateText == null || dateText.isBlank()) return "";
        for (DateTimeFormatter fmt : DATE_PARSERS) {
            try {
                return DOW_FMT.format(LocalDate.parse(dateText.trim(), fmt));
            } catch (DateTimeParseException ignore) {}
        }
        return dateText;
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

    private static String pctFromMap(Map<String, Object> map, String curKey, String prevKey) {
        BigDecimal current = toDecimal(map != null ? map.get(curKey) : null);
        BigDecimal previous = toDecimal(map != null ? map.get(prevKey) : null);
        if (previous.compareTo(BigDecimal.ZERO) == 0) return "0";
        BigDecimal pct = current.subtract(previous)
                .divide(previous, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(1, RoundingMode.HALF_UP);
        return pct.stripTrailingZeros().toPlainString();
    }

    private static String compactFromMap(Map<String, Object> map, String key) {
        return formatCompact(toDecimal(map != null ? map.get(key) : null));
    }

    private static String formatCompact(BigDecimal n) {
        boolean neg = n.signum() < 0;
        BigDecimal abs = n.abs();
        String suffix;
        BigDecimal val;

        if (abs.compareTo(BILLION) >= 0) { val = abs.divide(BILLION, 2, RoundingMode.HALF_UP); suffix = "B"; }
        else if (abs.compareTo(MILLION) >= 0) { val = abs.divide(MILLION, 2, RoundingMode.HALF_UP); suffix = "M"; }
        else if (abs.compareTo(THOUSAND) >= 0) { val = abs.divide(THOUSAND, 2, RoundingMode.HALF_UP); suffix = "K"; }
        else { val = abs.setScale(2, RoundingMode.HALF_UP); suffix = ""; }

        String core = val.stripTrailingZeros().toPlainString();
        if ("-0".equals(core)) core = "0";
        return (neg ? "-" : "") + core + suffix;
    }
}
