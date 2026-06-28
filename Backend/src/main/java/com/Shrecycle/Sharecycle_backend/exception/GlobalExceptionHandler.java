package com.Shrecycle.Sharecycle_backend.exception;

import com.Shrecycle.Sharecycle_backend.Response;
import com.Shrecycle.Sharecycle_backend.ResponseException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Global exception handler for the application.
 * Catches exceptions thrown by controllers and returns appropriate HTTP responses.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(SecurityException.class)
    public ResponseEntity<?> handleSecurityException(SecurityException ex) {
        return this.buildResponse(HttpStatus.FORBIDDEN.value(), ex.getMessage(), null);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<?> handleRuntimeException(RuntimeException ex) {
        return this.buildResponse(HttpStatus.INTERNAL_SERVER_ERROR.value(), ex.getMessage(), null);
    }

    @ExceptionHandler(ResponseException.class)
    public ResponseEntity<?> handleException(ResponseException e) {
        return this.buildResponse(e.getStatusCode(), e.getMessage(), null);
    }

    private ResponseEntity<?> buildResponse(int status, String message, Map<?, ?> data) {
        var body = Response.builder()
                .timestamp(LocalDateTime.now())
                .statusCode(status)
                .message(message)
                .data(null)
                .build();

        return ResponseEntity
                .status(body.getStatusCode())
                .body(body);
    }
}
