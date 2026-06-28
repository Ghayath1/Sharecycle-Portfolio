package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.dto.AdminUpdateUserRequest;
import com.Shrecycle.Sharecycle_backend.dto.UpdateUserRequest;
import com.Shrecycle.Sharecycle_backend.dto.UserDTO;
import com.Shrecycle.Sharecycle_backend.dto.UserProfileDTO;
import com.Shrecycle.Sharecycle_backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * Controller for user-related operations.
 * Provides endpoints for retrieving and updating user profiles,
 * as well as administrative functions for managing users.
 */
@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * Retrieves the details of the currently authenticated user.
     * @param userDetails The details of the authenticated user.
     * @return A response entity with the user's data.
     */
    @GetMapping("/me")
    public ResponseEntity<UserDTO> getCurrentUser(@AuthenticationPrincipal UserDetails userDetails) {
        String email = userDetails.getUsername();
        return ResponseEntity.ok(userService.getCurrentUser(email));
    }

    /**
     * Retrieves the profile of the currently authenticated user.
     * @param userDetails The details of the authenticated user.
     * @return A response entity with the user's profile data.
     */
    @GetMapping("/profile")
    public ResponseEntity<UserDTO> getProfile(@AuthenticationPrincipal UserDetails userDetails) {
        String email = userDetails.getUsername();
        return ResponseEntity.ok(userService.getUserByEmail(email));
    }

    /**
     * Retrieves a basic profile of the currently authenticated user.
     * @param userDetails The details of the authenticated user.
     * @return A response entity with the user's basic profile data.
     */
    @GetMapping("/profile/basic")
    public ResponseEntity<UserProfileDTO> getBasicProfile(@AuthenticationPrincipal UserDetails userDetails) {
        String email = userDetails.getUsername();
        return ResponseEntity.ok(userService.getUserProfile(email));
    }

    /**
     * Updates the profile of the currently authenticated user.
     * @param userDetails The details of the authenticated user.
     * @param request The request body with the updated user details.
     * @return A response entity with the updated user's data.
     */
    @PutMapping(value = "/profile", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<UserDTO> updateProfileJson(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateUserRequest request) {
        String email = userDetails.getUsername();
        return ResponseEntity.ok(userService.updateProfile(email, request));
    }

    /**
     * Updates the profile of the currently authenticated user with form data.
     * @param userDetails The details of the authenticated user.
     * @param name The user's new name.
     * @param emailNew The user's new email address.
     * @param birthDate The user's new date of birth (yyyy-MM-dd).
     * @param iphoneNumber The user's new phone number.
     * @param city The user's new city.
     * @param idCardNumber The user's new ID card number.
     * @param image An optional new profile image.
     * @return A response entity with the updated user's data.
     */
    @PutMapping(value = "/profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserDTO> updateProfileForm(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(value = "name",          required = false) String name,
            @RequestParam(value = "email",         required = false) String emailNew,
            @RequestParam(value = "birthDate",     required = false) String birthDate,
            @RequestParam(value = "iphoneNumber",  required = false) String iphoneNumber,
            @RequestParam(value = "city",          required = false) String city,
            @RequestParam(value = "idCardNumber",  required = false) String idCardNumber,
            @RequestPart(value = "image",          required = false) MultipartFile image
    ) {
        String principalEmail = userDetails.getUsername();
        UserDTO dto = userService.updateProfileWithForm(
                principalEmail, name, emailNew, birthDate, iphoneNumber, city, idCardNumber, image
        );
        return ResponseEntity.ok(dto);
    }

    /**
     * Retrieves a list of all regular users (admin only).
     * @return A response entity with a list of all users with the 'USER' role.
     */
    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<UserDTO>> getAllUsersWithRoleUser() {
        return ResponseEntity.ok(userService.getAllRegularUsers());
    }

    /**
     * Public endpoint to retrieve all users for POC/testing purposes.
     * WARNING: This endpoint is not secured and should only be used in development.
     * @return A response entity with a list of all users.
     */
    @GetMapping("/public/all")
    public ResponseEntity<List<UserDTO>> getAllUsersPublic() {
        return ResponseEntity.ok(userService.getAllRegularUsers());
    }

    /**
     * Updates a user's details as an admin.
     * @param userId The ID of the user to update.
     * @param request The request body with the updated user details.
     * @return A response entity with the updated user's data.
     */
    @PostMapping("/admin/update/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserDTO> updateUserByAdmin(
            @PathVariable Long userId,
            @RequestBody AdminUpdateUserRequest request) {
        return ResponseEntity.ok(userService.updateUserByAdmin(userId, request));
    }

    /**
     * Deletes a user as an admin.
     * @param userId The ID of the user to delete.
     * @return A response entity with a confirmation message.
     */
    @DeleteMapping("/admin/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> deleteUserByAdmin(@PathVariable Long userId) {
        userService.deleteUserByAdmin(userId);
        return ResponseEntity.ok("User deleted");
    }
}
