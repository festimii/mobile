// src/main/java/com/vivacrm/crm/config/DataSourceConfig.java
package com.vivacrm.crm.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfig {

    // PRIMARY -> used by JPA/Hibernate
    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource")
    public DataSource sqliteDataSource() {
        return DataSourceBuilder.create()
                .type(HikariDataSource.class)
                .build();
    }

    // SECONDARY -> SQL Server (no JPA)
    @Bean(name = "sqlServerDataSource")
    @Lazy
    @ConditionalOnProperty(prefix = "sqlserver.datasource", name = "enabled", havingValue = "true", matchIfMissing = true)
    @ConfigurationProperties("sqlserver.datasource")
    public DataSource sqlServerDataSource() {
        return DataSourceBuilder.create()
                .type(HikariDataSource.class)
                .build();
    }

    @Bean(name = "sqlServerJdbcTemplate")
    @Lazy
    @ConditionalOnProperty(prefix = "sqlserver.datasource", name = "enabled", havingValue = "true", matchIfMissing = true)
    public JdbcTemplate sqlServerJdbcTemplate(@Qualifier("sqlServerDataSource") DataSource ds) {
        JdbcTemplate jt = new JdbcTemplate(ds);
        jt.setResultsMapCaseInsensitive(true);
        return jt;
    }
}
