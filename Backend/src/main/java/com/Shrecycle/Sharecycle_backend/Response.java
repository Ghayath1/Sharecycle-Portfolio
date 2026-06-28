package com.Shrecycle.Sharecycle_backend;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.time.LocalDateTime;
import java.util.Map;

@Setter
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Response {
    private int statusCode;
    private LocalDateTime timestamp;
    private String message;
    private Map<?, ?> data;
}
