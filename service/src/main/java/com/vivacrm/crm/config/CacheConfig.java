// src/main/java/com/vivacrm/crm/config/CacheConfig.java
package com.vivacrm.crm.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableCaching // uses Spring’s simple ConcurrentMap cache by default
public class CacheConfig {}
