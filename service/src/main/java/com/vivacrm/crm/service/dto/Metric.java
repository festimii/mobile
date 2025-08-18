// src/main/java/com/vivacrm/crm/service/dto/Metric.java
package com.vivacrm.crm.service.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public final class Metric {
    private final String name;
    private final String value;
    private final List<Metric> subMetrics;

    public Metric(String name, String value) {
        this(name, value, null);
    }

    public Metric(String name, String value, List<Metric> subMetrics) {
        this.name = name;
        this.value = value;
        this.subMetrics = subMetrics;
    }

    public String getName() { return name; }
    public String getValue() { return value; }
    public List<Metric> getSubMetrics() { return subMetrics; }
}
