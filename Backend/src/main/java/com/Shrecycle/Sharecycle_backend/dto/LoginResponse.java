package com.Shrecycle.Sharecycle_backend.dto;

/**
 * Data Transfer Object for a user login response.
 */
public class LoginResponse {
    private String token;
    private String status;
    private UserDTO user;

    /**
     * Constructs a new LoginResponse.
     * @param token The JWT token.
     * @param status The login status.
     * @param user The user details.
     */
    public LoginResponse(String token, String status, UserDTO user) {
        this.token = token;
        this.status = status;
        this.user = user;
    }

    /**
     * Gets the JWT token.
     * @return The JWT token.
     */
    public String getToken() {
        return token;
    }

    /**
     * Gets the login status.
     * @return The login status.
     */
    public String getStatus() {
        return status;
    }

    /**
     * Gets the user details.
     * @return The user details.
     */
    public UserDTO getUser() {
        return user;
    }
}
