package com.splitdebt.api;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
@SpringBootTest(properties={"spring.datasource.url=jdbc:h2:mem:context;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;NON_KEYWORDS=GROUPS;DB_CLOSE_DELAY=-1","spring.datasource.username=sa","spring.datasource.password="})
class ApiApplicationTests { @Test void contextLoads() {} }
