// src/main/java/com/vivacrm/crm/service/dto/DashboardPayload.java
package com.vivacrm.crm.service.dto;

import java.util.List;

public record DashboardPayload(
        List<Metric> metrics,
        List<Point>  dailySeries,
        List<Point>  hourlySeries,
        List<StoreCompare> storeComparison
) {}
