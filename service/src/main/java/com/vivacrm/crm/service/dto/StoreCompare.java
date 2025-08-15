// src/main/java/com/vivacrm/crm/service/dto/StoreCompare.java
package com.vivacrm.crm.service.dto;

import java.math.BigDecimal;

/** Store comparison row with raw numerics and preformatted display strings. */
public record StoreCompare(
        String store,
        BigDecimal lastYear,
        BigDecimal thisYear,
        String lastYearDisplay,
        String thisYearDisplay
) {}
