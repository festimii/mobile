package com.vivacrm.crm.service.dto;

import java.math.BigDecimal;

public record StoreKpi(
        int storeId,
        String storeName,
        BigDecimal revenueToday,
        BigDecimal revenuePY,
        int txToday,
        int txPY,
        BigDecimal avgBasketToday,
        BigDecimal avgBasketPY,
        BigDecimal revenueDiff,
        BigDecimal revenuePct,
        int txDiff,
        BigDecimal txPct,
        BigDecimal avgBasketDiff,
        int peakHour,
        String peakHourLabel,
        BigDecimal peakHourRevenue,
        String topArtCode,
        BigDecimal topArtRevenue,
        String topArtName
) {}
