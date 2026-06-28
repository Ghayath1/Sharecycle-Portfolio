package com.Shrecycle.Sharecycle_backend;

public class AuthorizationException extends ResponseException {
    public AuthorizationException(String message) {
        super(message, 403);
    }
}
