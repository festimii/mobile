// src/main/java/com/vivacrm/crm/service/dto/StoreCompare.java
package com.vivacrm.crm.service.dto;

import java.math.BigDecimal;

public record StoreCompare(String store, BigDecimal lastYear, BigDecimal thisYear) { }
