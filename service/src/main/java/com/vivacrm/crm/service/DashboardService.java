package com.vivacrm.crm.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class DashboardService {
    private final JdbcTemplate jdbcTemplate;

    public DashboardService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Map<String, Object>> getMetrics() {
        try {
            SimpleJdbcCall call = new SimpleJdbcCall(jdbcTemplate).withProcedureName("SP_GetDashboardData");
            Map<String, Object> result = call.execute();

            return List.of(
                    Map.of("title", "Total Revenue", "value", String.valueOf(result.getOrDefault("TotalRevenue", "0"))),
                    Map.of("title", "Transactions", "value", String.valueOf(result.getOrDefault("Transactions", "0"))),
                    Map.of("title", "Avg Basket Size", "value", String.valueOf(result.getOrDefault("AvgBasketSize", "0"))),
                    Map.of("title", "Top Product Code", "value", String.valueOf(result.getOrDefault("TopProductCode", ""))),
                    Map.of("title", "Top Product Name", "value", String.valueOf(result.getOrDefault("TopProductName", ""))),
                    Map.of("title", "Returns Today", "value", String.valueOf(result.getOrDefault("ReturnsToday", "0"))),
                    Map.of("title", "Low Inventory Count", "value", String.valueOf(result.getOrDefault("LowInventoryCount", "0")))
            );
        } catch (Exception e) {
            return List.of(
                    Map.of("title", "Total Revenue", "value", "0"),
                    Map.of("title", "Transactions", "value", "0"),
                    Map.of("title", "Avg Basket Size", "value", "0"),
                    Map.of("title", "Top Product Code", "value", ""),
                    Map.of("title", "Top Product Name", "value", ""),
                    Map.of("title", "Returns Today", "value", "0"),
                    Map.of("title", "Low Inventory Count", "value", "0")
            );
        }
    }
}

