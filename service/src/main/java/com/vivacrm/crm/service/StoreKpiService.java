// src/main/java/com/vivacrm/crm/service/StoreKpiService.java
package com.vivacrm.crm.service;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import com.vivacrm.crm.service.dto.StoreKpi;

@Service
public class StoreKpiService {

    private final JdbcTemplate jdbc;

    public StoreKpiService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbc) {
        jdbc.setResultsMapCaseInsensitive(true);
        this.jdbc = jdbc;
    }

    /**
     * Caches the result by storeId in the in-memory ConcurrentMap cache named "storeKpi".
     * Null results are not cached.
     */
    @Transactional(readOnly = true)
    @Cacheable(cacheNames = "storeKpi", key = "#storeId", unless = "#result == null")
    public StoreKpi getStoreKpi(int storeId) {
        // If your proc supports it, prefer parameterized: "EXEC SP_GetStoreKPI @StoreId = ?"
        // return jdbc.queryForObject("EXEC SP_GetStoreKPI @StoreId = ?", mapper, storeId);
        List<Map<String, Object>> rows = jdbc.queryForList("EXEC SP_GetStoreKPI");
        Map<String, Object> row = rows.stream()
                .filter(r -> Objects.toString(r.get("StoreId"), "").equals(String.valueOf(storeId)))
                .findFirst()
                .orElse(Collections.emptyMap());
        return mapRow(row);
    }

    /** Evict a single store’s cached KPI (call after writing new data for that store). */
    @CacheEvict(cacheNames = "storeKpi", key = "#storeId")
    public void evictStoreKpi(int storeId) {
        // no-op; annotation performs eviction
    }

    /** Evict all cached KPIs (call after bulk loads/ETL). */
    @CacheEvict(cacheNames = "storeKpi", allEntries = true)
    public void evictAllStoreKpi() {
        // no-op; annotation performs eviction
    }

    private StoreKpi mapRow(Map<String, Object> r) {
        if (r == null || r.isEmpty()) return null;
        return new StoreKpi(
                toInt(r.get("StoreId")),
                asString(r.get("StoreName")),
                toDecimal(r.get("RevenueToday")),
                toDecimal(r.get("RevenuePY")),
                toInt(r.get("TxToday")),
                toInt(r.get("TxPY")),
                toDecimal(r.get("AvgBasketToday")),
                toDecimal(r.get("AvgBasketPY")),
                toDecimal(r.get("RevenueDiff")),
                toDecimal(r.get("RevenuePct")),
                toInt(r.get("TxDiff")),
                toDecimal(r.get("TxPct")),
                toDecimal(r.get("AvgBasketDiff")),
                toInt(r.get("PeakHour")),
                asString(r.get("PeakHourLabel")),
                toDecimal(r.get("PeakHourRevenue")),
                asString(r.get("TopArtCode")),
                toDecimal(r.get("TopArtRevenue")),
                asString(r.get("TopArtName"))
        );
    }

    private static BigDecimal toDecimal(Object v) {
        if (v == null) return BigDecimal.ZERO;
        if (v instanceof BigDecimal bd) return bd;
        if (v instanceof Number n) return BigDecimal.valueOf(n.doubleValue());
        try { return new BigDecimal(String.valueOf(v).trim()); }
        catch (Exception e) { return BigDecimal.ZERO; }
    }

    private static int toInt(Object v) {
        if (v instanceof Number n) return n.intValue();
        try { return Integer.parseInt(String.valueOf(v).trim()); }
        catch (Exception e) { return 0; }
    }

    private static String asString(Object v) {
        return v == null ? "" : String.valueOf(v);
    }
}
