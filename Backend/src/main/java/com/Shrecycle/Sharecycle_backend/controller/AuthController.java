package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.dto.LoginRequest;
import com.Shrecycle.Sharecycle_backend.dto.*;
import com.Shrecycle.Sharecycle_backend.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * Controller for authentication-related operations.
 * Provides endpoints for user login and registration.
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * Authenticates a user and returns a JWT.
     * @param request The login request containing the user's credentials.
     * @return A response containing the JWT and user details.
     */
    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

    /**
     * Registers a new user.
     * @param request The signup request containing the new user's details.
     * @return The created user's data.
     */
    @PostMapping(value = "/signup", consumes = MediaType.APPLICATION_JSON_VALUE)
    public UserDTO signupJson(@RequestBody SignupRequest request) {
        return authService.register(request);
    }

    /**
     * Registers a new user with an optional profile image.
     * @param firstName The user's first name.
     * @param lastName The user's last name.
     * @param email The user's email address.
     * @param password The user's password.
     * @param birthDate The user's date of birth (yyyy-MM-dd).
     * @param image An optional profile image.
     * @return The created user's data.
     */
    @PostMapping(value = "/signup", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UserDTO signupForm(
            @RequestParam String firstName,
            @RequestParam String lastName,
            @RequestParam String email,
            @RequestParam String password,
            @RequestParam String birthDate,
            @RequestPart(value = "image", required = false) MultipartFile image
    ) {
        return authService.registerMultipart(firstName, lastName, email, password, birthDate, image);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<String> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok("OTP sent to your email.");
    }

    @PostMapping("/reset-password")
    public ResponseEntity<String> resetPassword(@RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok("Password reset successfully.");
    }
}
