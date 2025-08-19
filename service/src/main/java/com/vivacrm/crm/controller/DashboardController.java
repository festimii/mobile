// src/main/java/com/vivacrm/crm/controller/DashboardController.java
package com.vivacrm.crm.controller;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.dto.DashboardPayload;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;
    public DashboardController(DashboardService dashboardService) { this.dashboardService = dashboardService; }

    /** Returns cached metrics unless `refresh=true` is provided. */
    @GetMapping("/metrics")
    public DashboardPayload metrics(
            @RequestParam(name = "refresh", defaultValue = "false") boolean refresh,
            @RequestParam(name = "forDate", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime forDate) {

        if (forDate != null) {
            return dashboardService.getMetrics(forDate);
        }
        return refresh ? dashboardService.refreshMetrics() : dashboardService.getMetrics();
    }

    /** Manually evict cache (reset). */
    @PostMapping("/metrics/reset")
    public ResponseEntity<Void> reset() {
        dashboardService.resetMetrics();
        return ResponseEntity.noContent().build();
    }
}
