// src/main/java/com/vivacrm/crm/service/DashboardService.java
package com.vivacrm.crm.service;

import com.vivacrm.crm.service.dto.*;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.jdbc.core.ColumnMapRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
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
    private final SimpleJdbcCall spResultSet; // result-set only (no OUT-param fallback)

    public DashboardService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbcTemplate) {
        jdbcTemplate.setResultsMapCaseInsensitive(true);
        this.sqlServerJdbc = jdbcTemplate;

        this.spResultSet = new SimpleJdbcCall(sqlServerJdbc)
                .withSchemaName("dbo")
                .withProcedureName("SP_GetDashboardData")  // <-- wrapper
                .withoutProcedureColumnMetaDataAccess()
                .declareParameters(
                        new SqlParameter("ForDate", Types.DATE),
                        new SqlParameter("AsOf",    Types.TIMESTAMP)
                )
                .returningResultSet("#result-set-1", new ColumnMapRowMapper())
                .returningResultSet("#result-set-2", new ColumnMapRowMapper())
                .returningResultSet("#result-set-3", new ColumnMapRowMapper())
                .returningResultSet("#result-set-4", new ColumnMapRowMapper());
    }


    /** Cached read: stays cached until explicitly refreshed/evicted. */
    @Cacheable(value = "dashboard", key = "'metrics'")
    public DashboardPayload getMetrics() {
        return loadMetrics(null);
    }

    /**
     * Return metrics for a specific date/time.
     * Results are cached per day to avoid repeated stored procedure calls
     * for the same historical date.
     */
    @Cacheable(value = "dashboard", key = "'metrics:' + #forDate.toLocalDate()")
    public DashboardPayload getMetrics(LocalDateTime forDate) {
        return loadMetrics(forDate);
    }

    /** Force-refresh cache and return fresh payload. */
    @CachePut(value = "dashboard", key = "'metrics'")
    public DashboardPayload refreshMetrics() {
        return loadMetrics(null);
    }

    /** Evict cached payload (manual reset). */
    @CacheEvict(value = "dashboard", key = "'metrics'")
    public void resetMetrics() { /* no-op */ }

    // ----------------- internal loader -----------------
    protected DashboardPayload loadMetrics(LocalDateTime dateTime) {
        final LocalDateTime now = LocalDateTime.now();
        final LocalDate today = now.toLocalDate();
        final LocalDateTime queryTime = ((dateTime != null) ? dateTime : now)
                .withMinute(0).withSecond(0).withNano(0);

        MapSqlParameterSource in = new MapSqlParameterSource();

// Wrapper logic: NULL => today (cut off to last completed hour inside SP)
// Non-null & not today => historic full day
        if (dateTime == null || queryTime.toLocalDate().isEqual(today)) {
            in.addValue("ForDate", null, Types.DATE);
            in.addValue("AsOf", java.sql.Timestamp.valueOf(queryTime), Types.TIMESTAMP);
        } else {
            in.addValue("ForDate", java.sql.Date.valueOf(queryTime.toLocalDate()), Types.DATE);
            in.addValue("AsOf", null, Types.TIMESTAMP);
        }

        List<Map<String, Object>> rs1 = Collections.emptyList();
        List<Map<String, Object>> rs2 = Collections.emptyList();
        List<Map<String, Object>> rs3 = Collections.emptyList();
        List<Map<String, Object>> rs4 = Collections.emptyList();
        Map<String, Object> metricsRow = Collections.emptyMap();

        Map<String, Object> out = spResultSet.execute(in);
        rs1 = getList(out, "#result-set-1", "rs");
        rs2 = getList(out, "#result-set-2", "daily");
        rs3 = getList(out, "#result-set-3", "hourly");
        rs4 = getList(out, "#result-set-4", "stores");
        metricsRow = rs1.isEmpty() ? Collections.emptyMap() : rs1.get(0);

        // ---- Top Pika analytics (rank, share, YoY, gap to #2, top-3 summary) ----
        final String topStoreName = asString(metricsRow, "TopStoreName", "").trim();
        final String topStoreOE   = asString(metricsRow, "TopStoreOE", "").trim();
        final BigDecimal topStoreRevenue = toDecimal(metricsRow.get("TopStoreRevenue"));
        final BigDecimal totalRevenue    = toDecimal(metricsRow.get("TotalRevenue"));

        TopStoreStats topStats = analyzeTopStore(rs4, "Store", "LastYear", "ThisYear",
                topStoreName, topStoreRevenue, totalRevenue);

        // ---- grouped metrics with sub-metrics ----
        List<Metric> metrics = List.of(
                m("Shitjet Sod", compactFromMap(metricsRow, "TotalRevenue"), List.of(
                        m("VS Dje", compactFromMap(metricsRow, "RevenueVsYesterdayPct") + "%"),
                        m("Vs Viti Kaluar", compactFromMap(metricsRow, "RevenueVsPYPct") + "%"),
                        m("Total Viti Kaluar", compactFromMap(metricsRow, "TotalRevenuePY")),
                        m("Dje", compactFromMap(metricsRow, "RevenueYesterday"))
                )),

                m("Top Pika", topStoreOE.isEmpty() ? topStoreName : topStoreOE, List.of(
                        m("Emri", topStoreName),
                        m("Shitjet e Pikes", formatCompact(topStoreRevenue)),
                        m("Kontributi %", topStats.contributionPct),
                        m("Vs Viti Kaluar", topStats.vsPyPct),
                        m("Renditja", topStats.rank > 0 ? String.valueOf(topStats.rank) : "n/a"),
                        m("Diferenca me #2", formatCompact(topStats.gapToSecond)),
                        m("Top 3 Pika", topStats.top3Summary)
                )),
                m("Kuponat   Fiskal", compactFromMap(metricsRow, "Transactions"), List.of(
                        m("Vs Viti Kaluar", pctFromMap(metricsRow, "Transactions", "TransactionsPY") + "%"),
                        m("Viti Kaluar", compactFromMap(metricsRow, "TransactionsPY")),
                        m("Ora Me Trafik", asString(metricsRow, "PeakHour", ""))
                )),

                m("Shporta Mesatare", compactFromMap(metricsRow, "AvgBasketSize"), List.of(
                        m("Vs Viti Kaluar", pctFromMap(metricsRow, "AvgBasketSize", "AvgBasketSizePY") + "%"),
                        m("Viti Kaluar", compactFromMap(metricsRow, "AvgBasketSizePY"))
                ))
        );

        // Series
        List<Point> dailySeries  = mapDailyPointsWithDOW(rs2, "Label", "Amount");
        List<Point> hourlySeries = mapHourlyCompressed(rs3, "HourLabel", "Amount");
        List<StoreCompare> storeComparison = mapStores(rs4, "Store", "LastYear", "ThisYear");

        return new DashboardPayload(metrics, dailySeries, hourlySeries, storeComparison);
    }

    // ----------------- Top store analytics -----------------
    private static final class TopStoreStats {
        final String contributionPct;      // top store revenue / total revenue
        final String vsPyPct;              // (thisYear - lastYear)/lastYear
        final int    rank;                 // 1-based rank among stores by ThisYear
        final BigDecimal gapToSecond;      // top - second by ThisYear (0 if not applicable)
        final String top3Summary;          // "1) StoreA: 16.7K; 2) StoreB: 12.3K; 3) StoreC: 9.9K"

        TopStoreStats(String contributionPct, String vsPyPct, int rank, BigDecimal gapToSecond, String top3Summary) {
            this.contributionPct = contributionPct;
            this.vsPyPct = vsPyPct;
            this.rank = rank;
            this.gapToSecond = gapToSecond;
            this.top3Summary = top3Summary;
        }
    }

    private static TopStoreStats analyzeTopStore(List<Map<String, Object>> rows,
                                                 String storeCol, String lastYearCol, String thisYearCol,
                                                 String topStoreName,
                                                 BigDecimal topStoreRevenue,
                                                 BigDecimal totalRevenue) {
        record Entry(String store, BigDecimal lastYear, BigDecimal thisYear) {}
        List<Entry> list = new ArrayList<>();
        if (rows != null) {
            for (Map<String, Object> r : rows) {
                String s = String.valueOf(r.getOrDefault(storeCol, "")).trim();
                BigDecimal ly = toDecimal(r.get(lastYearCol));
                BigDecimal ty = toDecimal(r.get(thisYearCol));
                list.add(new Entry(s, ly, ty));
            }
        }
        list.sort((a, b) -> b.thisYear.compareTo(a.thisYear));

        int rank = -1;
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).store.equalsIgnoreCase(topStoreName)) {
                rank = i + 1;
                break;
            }
        }
        if (rank < 0 && !list.isEmpty() && topStoreRevenue.signum() > 0) {
            BigDecimal bestDiff = null; int bestIdx = -1;
            for (int i = 0; i < list.size(); i++) {
                BigDecimal diff = list.get(i).thisYear.subtract(topStoreRevenue).abs();
                if (bestDiff == null || diff.compareTo(bestDiff) < 0) { bestDiff = diff; bestIdx = i; }
            }
            rank = bestIdx >= 0 ? bestIdx + 1 : -1;
        }

        BigDecimal gap2 = BigDecimal.ZERO;
        if (!list.isEmpty() && rank == 1 && list.size() >= 2) {
            gap2 = list.get(0).thisYear.subtract(list.get(1).thisYear);
        }

        String vsPyPct = "n/a";
        if (rank > 0) {
            Entry e = list.get(rank - 1);
            if (e.lastYear.signum() > 0) vsPyPct = fmtPct(e.thisYear.subtract(e.lastYear), e.lastYear);
            else if (e.thisYear.signum() > 0) vsPyPct = "100%";
            else vsPyPct = "0%";
        }
        String contrib = fmtPct(topStoreRevenue, totalRevenue);

        StringBuilder sb = new StringBuilder();
        int topN = Math.min(3, list.size());
        for (int i = 0; i < topN; i++) {
            Entry e = list.get(i);
            if (i > 0) sb.append("; ");
            sb.append(i + 1).append(") ").append(e.store).append(": ").append(formatCompact(e.thisYear));
        }
        String top3 = sb.toString();

        return new TopStoreStats(contrib, vsPyPct, rank, gap2, top3);
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

        List<HourBin> bins = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            String lbl = String.valueOf(r.getOrDefault(labelCol, "")).trim();
            int hour = parseHour(lbl);
            if (hour < 0) continue;
            BigDecimal val = toDecimal(r.get(amtCol));
            bins.add(new HourBin(hour, lbl, val));
        }
        bins.sort(Comparator.comparingInt(b -> b.hour));

        List<HourBin> nonZero = new ArrayList<>();
        for (HourBin b : bins) if (b.value.compareTo(BigDecimal.ZERO) > 0) nonZero.add(b);
        if (nonZero.isEmpty()) return List.of();

        List<HourBin> kept = new ArrayList<>();
        for (int i = 0; i < nonZero.size(); i++) {
            HourBin cur = nonZero.get(i);
            if (cur.value.compareTo(FOUR_HUNDRED) <= 0) {
                if (i + 1 < nonZero.size()) nonZero.get(i + 1).value = nonZero.get(i + 1).value.add(cur.value);
                else if (!kept.isEmpty()) kept.get(kept.size() - 1).value = kept.get(kept.size() - 1).value.add(cur.value);
                else kept.add(cur);
                continue;
            }
            kept.add(cur);
        }

        List<Point> out = new ArrayList<>(kept.size());
        for (HourBin b : kept) out.add(new Point(b.label, b.value, formatCompact(b.value)));
        return out;
    }

    private static class HourBin {
        final int hour; final String label; BigDecimal value;
        HourBin(int hour, String label, BigDecimal value) { this.hour = hour; this.label = label; this.value = value; }
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
                return DOW_FMT.format(java.time.LocalDate.parse(dateText.trim(), fmt));
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

    private static String fmtPct(BigDecimal part, BigDecimal whole) {
        if (whole == null || whole.signum() == 0 || part == null) return "0%";
        BigDecimal pct = part.divide(whole, 6, RoundingMode.HALF_UP).multiply(new BigDecimal("100"));
        String s = pct.setScale(1, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
        if ("-0".equals(s)) s = "0";
        return s + "%";
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
