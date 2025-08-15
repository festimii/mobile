// src/main/java/com/vivacrm/crm/config/DataSourceConfig.java
package com.vivacrm.crm.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfig {

    @Bean(name = "sqliteDataSource")
    @Primary
    @ConfigurationProperties("spring.datasource")
    public DataSource sqliteDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    @Bean(name = "sqlServerDataSource")
    @ConfigurationProperties("sqlserver.datasource")
    public DataSource sqlServerDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    @Bean(name = "sqlServerJdbcTemplate")
    public JdbcTemplate sqlServerJdbcTemplate(
            @SuppressWarnings("SpringJavaInjectionPointsAutowiringInspection")
            @Qualifier("sqlServerDataSource") DataSource ds) {
        JdbcTemplate jt = new JdbcTemplate(ds);
        jt.setResultsMapCaseInsensitive(true);
        return jt;
    }
}
