// src/main/java/com/vivacrm/crm/config/CacheConfig.java
package com.vivacrm.crm.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableCaching // uses Spring’s simple ConcurrentMap cache by default
@EnableScheduling
public class CacheConfig {}
