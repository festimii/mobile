// src/main/java/com/vivacrm/crm/service/dto/Point.java
package com.vivacrm.crm.service.dto;

import java.math.BigDecimal;

/** Time-series point with raw numeric value and a preformatted display string. */
public record Point(String label, BigDecimal amount, String display) {}
