// src/main/java/com/vivacrm/crm/schedule/CacheRefreshScheduler.java
package com.vivacrm.crm.schedule;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.StoreKpiService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Component
public class CacheRefreshScheduler {

    private final DashboardService dashboardService;
    private final StoreKpiService storeKpiService;

    /** Tracks last hour when caches were refreshed. */
    private LocalDateTime lastRefresh = LocalDateTime.MIN;

    public CacheRefreshScheduler(DashboardService dashboardService,
                                 StoreKpiService storeKpiService) {
        this.dashboardService = dashboardService;
        this.storeKpiService = storeKpiService;
    }

    /**
     * Runs five minutes after the top of each hour (e.g. 10:05).
     * Zone can be omitted if you want server default.
     */
    @Scheduled(cron = "${app.cache.refresh.cron:0 5 * * * *}", zone = "Europe/Belgrade")
    public void scheduledRefresh() {
        refreshAll();
    }

    /** Refresh caches for dashboard payload and store KPI entries. */
    @Transactional(readOnly = true)
    public synchronized void refreshAll() {
        try {
            dashboardService.refreshMetrics();
        } catch (Exception ignore) { /* log if desired */ }

        try {
            storeKpiService.refreshAllStores();
        } catch (Exception ignore) { /* log if desired */ }

        lastRefresh = LocalDateTime.now().truncatedTo(ChronoUnit.HOURS);
    }

    /**
     * Fallback for environments where cron jobs are not executed (e.g. Windows
     * servers). This triggers a refresh once per hour when invoked.
     */
    public synchronized void refreshIfStale() {
        LocalDateTime nowHour = LocalDateTime.now().truncatedTo(ChronoUnit.HOURS);
        if (lastRefresh.isBefore(nowHour)) {
            refreshAll();
        }
    }
}
