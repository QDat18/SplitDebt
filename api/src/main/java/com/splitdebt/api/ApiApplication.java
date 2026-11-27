/**
 * Trách nhiệm file: Khởi động ứng dụng Spring Boot và cấu hình quá trình quét các thành phần backend.
 */

package com.splitdebt.api;

import com.splitdebt.api.config.LegalProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(LegalProperties.class)
public class ApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(ApiApplication.class, args);
	}

}
