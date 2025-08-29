// src/main/java/com/vivacrm/crm/schedule/CacheRefreshScheduler.java
package com.vivacrm.crm.schedule;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.StoreKpiService;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;

@Component
public class CacheRefreshScheduler {

    private final DashboardService dashboardService;
    private final StoreKpiService storeKpiService;
    private final Duration refreshInterval;
    private final ZoneId zoneId;

    /** Tracks last time when caches were refreshed. */
    private LocalDateTime lastRefresh = LocalDateTime.MIN;

    public CacheRefreshScheduler(DashboardService dashboardService,
                                 StoreKpiService storeKpiService,
                                 @Value("${app.cache.refresh.interval:PT1H}") Duration refreshInterval,
                                 @Value("${app.timezone:UTC}") String zone) {
        this.dashboardService = dashboardService;
        this.storeKpiService = storeKpiService;
        this.refreshInterval = refreshInterval;
        this.zoneId = ZoneId.of(zone);
    }

    /** Refresh caches for dashboard payload and store KPI entries. */
    public synchronized void refreshAll() {
        try {
            dashboardService.refreshMetrics();
        } catch (Exception ignore) { /* log if desired */ }

        try {
            storeKpiService.refreshAllStores();
        } catch (Exception ignore) { /* log if desired */ }

        lastRefresh = LocalDateTime.now(zoneId);
    }

    /** Warm caches at application startup so store KPIs and dashboard metrics
     *  are immediately available and refreshed together. */
    @PostConstruct
    public void warmOnStartup() {
        refreshAll();
    }

    /**
     * Windows-friendly refresher invoked on incoming requests. Ensures caches
     * are updated once per configured interval even when scheduled jobs are
     * unavailable.
     */
    public synchronized void refreshIfStale() {
        LocalDateTime now = LocalDateTime.now(zoneId);
        if (Duration.between(lastRefresh, now).compareTo(refreshInterval) >= 0) {
            refreshAll();
        }
    }

    @Scheduled(cron = "${app.cache.refresh.cron:0 0 * * * *}", zone = "${app.timezone:UTC}")
    public void scheduledRefresh() {
        refreshAll();
    }
}
