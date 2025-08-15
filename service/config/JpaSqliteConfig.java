// src/main/java/com/vivacrm/crm/config/JpaSqliteConfig.java
package com.vivacrm.crm.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.*;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.*;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.vivacrm.crm.jpa",              // << put your JPA repositories here
        entityManagerFactoryRef = "sqliteEmf",
        transactionManagerRef = "sqliteTx"
)
public class JpaSqliteConfig {

    @Bean
    public LocalContainerEntityManagerFactoryBean sqliteEmf(
            EntityManagerFactoryBuilder builder,
            @Qualifier("sqliteDataSource") DataSource ds) {

        return builder
                .dataSource(ds)
                .packages("com.vivacrm.crm.jpa")            // << entities package
                .persistenceUnit("sqlitePU")
                .build();
    }

    @Bean
    public PlatformTransactionManager sqliteTx(
            @Qualifier("sqliteEmf") LocalContainerEntityManagerFactoryBean emf) {
        return new JpaTransactionManager(emf.getObject());
    }
}
