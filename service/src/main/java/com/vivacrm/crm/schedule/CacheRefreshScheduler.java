// src/main/java/com/vivacrm/crm/schedule/CacheRefreshScheduler.java
package com.vivacrm.crm.schedule;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.StoreKpiService;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class CacheRefreshScheduler {

    private final DashboardService dashboardService;
    private final StoreKpiService storeKpiService;

    public CacheRefreshScheduler(DashboardService dashboardService,
                                 StoreKpiService storeKpiService) {
        this.dashboardService = dashboardService;
        this.storeKpiService = storeKpiService;
    }

    /**
     * Runs shortly after the top of each hour (e.g. 10:01).
     * Zone can be omitted if you want server default.
     */
    @Scheduled(cron = "${app.cache.refresh.cron:0 1 * * * *}", zone = "Europe/Belgrade")
    @Transactional(readOnly = true)
    public void refreshAll() {
        // Refresh dashboard payload cache
        try {
            dashboardService.refreshMetrics(); // @CachePut updates dashboard::metrics
        } catch (Exception ignore) { /* log if desired */ }

        // Refresh all store KPI entries
        try {
            storeKpiService.refreshAllStores(); // clears & repopulates storeKpi cache
        } catch (Exception ignore) { /* log if desired */ }
    }
}
