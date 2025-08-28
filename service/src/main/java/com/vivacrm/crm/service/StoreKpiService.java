// src/main/java/com/vivacrm/crm/service/StoreKpiService.java
package com.vivacrm.crm.service;

import com.vivacrm.crm.service.dto.StoreKpi;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.cache.Cache;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.CachePut;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

@Service
public class StoreKpiService {

    private static final String CACHE_NAME = "storeKpi";

    private final JdbcTemplate jdbc;
    private final CacheManager cacheManager;
    private final AtomicBoolean cacheWarmed = new AtomicBoolean(false);

    public StoreKpiService(@Qualifier("mssqlJdbcTemplate") JdbcTemplate jdbc,
                           CacheManager cacheManager) {
        jdbc.setResultsMapCaseInsensitive(true);
        this.jdbc = jdbc;
        this.cacheManager = cacheManager;
    }

    @Transactional(readOnly = true)
    public StoreKpi getStoreKpi(int storeId) {
        warmCacheIfNeeded();

        StoreKpi fromCache = cacheGet(storeId);
        if (fromCache != null) return fromCache;

        // Fallback: fetch and cache only the requested store
        Timestamp asOf = Timestamp.valueOf(LocalDateTime.now());
        List<Map<String, Object>> rows = jdbc.queryForList("EXEC SP_GetStoreKPI @AsOf = ?", asOf);
        Map<String, Object> row = rows.stream()
                .filter(r -> Objects.toString(r.get("StoreId"), "").equals(String.valueOf(storeId)))
                .findFirst()
                .orElse(Collections.emptyMap());

        StoreKpi kpi = mapRow(row);
        int id = toInt(row.get("StoreId"));
        if (kpi != null && id != 0) cachePut(id, kpi);
        return kpi;
    }

    /** Force-refresh cache for a single store and return fresh KPI. */
    @CachePut(cacheNames = CACHE_NAME, key = "#storeId")
    @Transactional(readOnly = true)
    public StoreKpi refreshStoreKpi(int storeId) {
        Timestamp asOf = Timestamp.valueOf(LocalDateTime.now());
        List<Map<String, Object>> rows = jdbc.queryForList("EXEC SP_GetStoreKPI @AsOf = ?", asOf);
        Map<String, Object> row = rows.stream()
                .filter(r -> Objects.toString(r.get("StoreId"), "").equals(String.valueOf(storeId)))
                .findFirst()
                .orElse(Collections.emptyMap());

        return mapRow(row);
    }

    @Transactional(readOnly = true)
    public void scheduledRefreshAllStores() {
        refreshAllStores();
    }

    @Transactional(readOnly = true)
    public void refreshAllStores() {
        Cache cache = getCache();
        if (cache == null) return;

        Timestamp asOf = Timestamp.valueOf(LocalDateTime.now());
        List<Map<String, Object>> rows = jdbc.queryForList("EXEC SP_GetStoreKPI @AsOf = ?", asOf);
        cache.clear();
        for (Map<String, Object> r : rows) {
            StoreKpi kpi = mapRow(r);
            int id = toInt(r.get("StoreId"));
            if (kpi != null && id != 0) cache.put(id, kpi);
        }
        cacheWarmed.set(true);
    }

    @CacheEvict(cacheNames = CACHE_NAME, key = "#storeId")
    public void evictStoreKpi(int storeId) {}

    @CacheEvict(cacheNames = CACHE_NAME, allEntries = true)
    public void evictAllStoreKpi() { cacheWarmed.set(false); }

    /* ---------------------- internals ---------------------- */

    private void warmCacheIfNeeded() {
        if (cacheWarmed.get()) return;
        if (cacheWarmed.compareAndSet(false, true)) {
            Timestamp asOf = Timestamp.valueOf(LocalDateTime.now());
            List<Map<String, Object>> rows = jdbc.queryForList("EXEC SP_GetStoreKPI @AsOf = ?", asOf);
            Cache cache = getCache();
            if (cache == null) return;

            for (Map<String, Object> r : rows) {
                StoreKpi kpi = mapRow(r);
                int id = toInt(r.get("StoreId"));
                if (kpi != null && id != 0) cache.put(id, kpi);
            }
        }
    }

    private Cache getCache() { return cacheManager.getCache(CACHE_NAME); }

    private StoreKpi cacheGet(int storeId) {
        Cache.ValueWrapper w = getCache() == null ? null : getCache().get(storeId);
        return w == null ? null : (StoreKpi) w.get();
    }

    private void cachePut(int storeId, StoreKpi kpi) {
        Cache cache = getCache();
        if (cache != null) cache.put(storeId, kpi);
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
