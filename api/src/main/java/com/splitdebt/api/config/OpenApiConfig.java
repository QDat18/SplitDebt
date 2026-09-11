package com.splitdebt.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SplitDebt RESTful API Documentation")
                        .description("Tài liệu API phân hệ Backend dự án SplitDebt - Phát triển bởi Team IUMAITRUONG (Dev 2: Đạt)")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Dev 2 (Đạt) - Team IUMAITRUONG")
                                .email("backend@splitdebt.com")))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Local Development Server")
                ));
    }
}
