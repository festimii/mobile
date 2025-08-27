package com.vivacrm.crm.controller;

import com.vivacrm.crm.schedule.CacheRefreshScheduler;
import com.vivacrm.crm.service.StoreKpiService;
import com.vivacrm.crm.service.dto.StoreKpi;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/stores")
public class StoreController {

    private final StoreKpiService kpiService;
    private final CacheRefreshScheduler refreshScheduler;

    public StoreController(StoreKpiService kpiService,
                           CacheRefreshScheduler refreshScheduler) {
        this.kpiService = kpiService;
        this.refreshScheduler = refreshScheduler;
    }

    @GetMapping("/{storeId}/kpi")
    public StoreKpi kpi(@PathVariable int storeId,
                        @RequestParam(name = "refresh", defaultValue = "false") boolean refresh) {
        refreshScheduler.refreshIfStale();
        return refresh ? kpiService.refreshStoreKpi(storeId) : kpiService.getStoreKpi(storeId);
    }

    /** Manually evict all cached KPI entries. */
    @PostMapping("/kpi/reset")
    public ResponseEntity<Void> reset() {
        kpiService.evictAllStoreKpi();
        return ResponseEntity.noContent().build();
    }
}
