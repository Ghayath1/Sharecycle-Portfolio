package com.Shrecycle.Sharecycle_backend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Configures web-related settings for the application.
 * This class is responsible for setting up resource handlers.
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    /**
     * Configures resource handlers to serve static files.
     * Maps the `/uploads/**` URL path to the directory specified by `app.upload.dir`.
     * @param registry The resource handler registry.
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // e.g. http://localhost:8080/uploads/<file>
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadDir + "/");
    }
}
