// src/main/java/com/vivacrm/crm/config/SqlServerConfig.java
package com.vivacrm.crm.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class SqlServerConfig {

    @Bean(name = "mssqlDataSource") // <-- renamed to avoid clash
    @ConfigurationProperties("sqlserver.datasource")
    public DataSource mssqlDataSource() {
        return new HikariDataSource();
    }

    @Bean(name = "mssqlJdbcTemplate") // <-- renamed accordingly
    public JdbcTemplate mssqlJdbcTemplate(@Qualifier("mssqlDataSource") DataSource ds) {
        JdbcTemplate jt = new JdbcTemplate(ds);
        jt.setResultsMapCaseInsensitive(true);
        return jt;
    }
}
