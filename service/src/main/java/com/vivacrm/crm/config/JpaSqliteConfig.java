// src/main/java/com/vivacrm/crm/config/JpaSqliteConfig.java
package com.vivacrm.crm.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.orm.jpa.EntityManagerFactoryBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;

@Configuration
@EnableJpaRepositories(
        basePackages = "com.vivacrm.crm.user",   // JPA repos for User live here
        entityManagerFactoryRef = "sqliteEmf",
        transactionManagerRef  = "sqliteTx"
)
public class JpaSqliteConfig {

    @Bean(name = "sqliteEmf")
    public LocalContainerEntityManagerFactoryBean sqliteEmf(
            EntityManagerFactoryBuilder builder,
            @Qualifier("sqliteDataSource") DataSource ds) {

        return builder
                .dataSource(ds)
                .packages("com.vivacrm.crm.user") // @Entity(User) package
                .persistenceUnit("sqlitePU")
                .build();
    }

    @Bean(name = "sqliteTx")
    public PlatformTransactionManager sqliteTx(
            @Qualifier("sqliteEmf") LocalContainerEntityManagerFactoryBean emf) {
        return new JpaTransactionManager(emf.getObject());
    }
}
