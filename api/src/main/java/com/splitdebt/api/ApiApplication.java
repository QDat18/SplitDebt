/**
 * Trách nhiệm file: Khởi động ứng dụng Spring Boot và cấu hình quá trình quét các thành phần backend.
 */

package com.splitdebt.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(ApiApplication.class, args);
	}

}
