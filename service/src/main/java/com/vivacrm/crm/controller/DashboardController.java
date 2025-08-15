// src/main/java/com/vivacrm/crm/controller/DashboardController.java
package com.vivacrm.crm.controller;

import com.vivacrm.crm.service.DashboardService;
import com.vivacrm.crm.service.dto.DashboardPayload;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;
    public DashboardController(DashboardService dashboardService) { this.dashboardService = dashboardService; }

    @GetMapping("/metrics")
    public DashboardPayload metrics() {
        return dashboardService.getMetrics();
    }
}
