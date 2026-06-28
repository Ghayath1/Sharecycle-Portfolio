package com.Shrecycle.Sharecycle_backend.dto;

/**
 * Data Transfer Object for a user login request.
 */
public class LoginRequest {
    private String email;
    private String password;

    /**
     * Gets the email address.
     * @return The email address.
     */
    public String getEmail() {
        return email;
    }

    /**
     * Sets the email address.
     * @param email The email address.
     */
    public void setEmail(String email) {
        this.email = email;
    }

    /**
     * Gets the password.
     * @return The password.
     */
    public String getPassword() {
        return password;
    }

    /**
     * Sets the password.
     * @param password The password.
     */
    public void setPassword(String password) {
        this.password = password;
    }
}
