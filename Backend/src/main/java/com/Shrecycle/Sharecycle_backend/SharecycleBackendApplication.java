package com.Shrecycle.Sharecycle_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * The main entry point for the Sharecycle backend application.
 */
@SpringBootApplication
@EnableJpaAuditing
public class SharecycleBackendApplication {

	/**
	 * Starts the Spring Boot application.
	 */
	public static void main(String[] args) {
		SpringApplication.run(SharecycleBackendApplication.class, args);
	}
}
