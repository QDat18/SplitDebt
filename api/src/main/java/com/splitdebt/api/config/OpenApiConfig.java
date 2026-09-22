package com.splitdebt.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    private static final String SECURITY_SCHEME_NAME = "Bearer Authentication";

    @Value("${server.port:8081}")
    private String serverPort;

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("SplitDebt RESTful API Documentation")
                        .description("Tài liệu API và công cụ kiểm thử phân hệ Backend dự án SplitDebt.\n\n"
                                + "🔐 **Hướng dẫn xác thực:**\n"
                                + "1. Gọi API `POST /api/auth/login` để lấy JWT Token.\n"
                                + "2. Nhấn nút **Authorize** ở góc phải trên, dán Token vào ô Value (không cần gõ chữ 'Bearer ').\n"
                                + "3. Nhấn **Authorize** để kích hoạt xác thực cho tất cả các API.")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("Dev 2 (Đạt) - Team IUMAITRUONG")
                                .email("backend@splitdebt.com"))
                        .license(new License().name("Apache 2.0").url("https://springdoc.org")))
                .servers(List.of(
                        new Server().url("http://localhost:" + serverPort).description("Local Development Server"),
                        new Server().url("/").description("Current Host Server")
                ))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                                .name(SECURITY_SCHEME_NAME)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Nhập JWT Token lấy từ API login")));
    }
}

