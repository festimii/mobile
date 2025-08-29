// src/main/java/com/vivacrm/crm/schedule/CacheRefreshScheduler.java
package com.vivacrm.crm.schedule;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.StoreKpiService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;

@Component
public class CacheRefreshScheduler {

    private final DashboardService dashboardService;
    private final StoreKpiService storeKpiService;
    private final Duration refreshInterval;

    /** Tracks last time when caches were refreshed. */
    private LocalDateTime lastRefresh = LocalDateTime.MIN;

    public CacheRefreshScheduler(DashboardService dashboardService,
                                 StoreKpiService storeKpiService,
                                 @Value("${app.cache.refresh.interval:PT1H}") Duration refreshInterval) {
        this.dashboardService = dashboardService;
        this.storeKpiService = storeKpiService;
        this.refreshInterval = refreshInterval;
    }

    /** Refresh caches for dashboard payload and store KPI entries. */
    public synchronized void refreshAll() {
        try {
            dashboardService.refreshMetrics();
        } catch (Exception ignore) { /* log if desired */ }

        try {
            storeKpiService.refreshAllStores();
        } catch (Exception ignore) { /* log if desired */ }

        lastRefresh = LocalDateTime.now();
    }

    /**
     * Windows-friendly refresher invoked on incoming requests. Ensures caches
     * are updated once per configured interval even when scheduled jobs are
     * unavailable.
     */
    public synchronized void refreshIfStale() {
        LocalDateTime now = LocalDateTime.now();
        if (Duration.between(lastRefresh, now).compareTo(refreshInterval) >= 0) {
            refreshAll();
        }
    }
}
