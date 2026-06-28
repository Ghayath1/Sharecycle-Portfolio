package com.Shrecycle.Sharecycle_backend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.modelmapper.ModelMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

@Configuration
public class AppConfig {

    @Bean
    public ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
        return builder.build();
    }

    /**
     * Creates a ModelMapper bean for object mapping.
     *
     * @return A ModelMapper object.
     */
    @Bean
    public ModelMapper modelMapper() {
        return new ModelMapper();
    }
}
