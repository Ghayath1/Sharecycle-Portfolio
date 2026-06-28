package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.dto.AdminDTO;
import com.Shrecycle.Sharecycle_backend.dto.AdminDashboardStatsDTO;
import com.Shrecycle.Sharecycle_backend.dto.AdminUpdateRequest;
import com.Shrecycle.Sharecycle_backend.dto.CreateAdminRequest;
import com.Shrecycle.Sharecycle_backend.service.AdminService;
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
 * Controller for admin-related operations.
 * Provides endpoints for creating, retrieving, updating, and deleting admins,
 * as well as accessing dashboard statistics.
 */
@RestController
@RequestMapping("/api/admins")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    /**
     * Retrieves dashboard statistics for the admin.
     *
     * @return The dashboard statistics.
     */
    @GetMapping("/profile")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> getAdmin(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(adminService.getAdminByEmail(userDetails.getUsername()));
    }

    /**
     * Creates a new admin.
     *
     * @param req The request body containing the new admin's details.
     * @return A response entity with the created admin's data.
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> createAdmin(@RequestBody CreateAdminRequest req) {
        return ResponseEntity.ok(adminService.createAdminByAdmin(req));
    }

    /**
     * Retrieves dashboard statistics for the admin.
     *
     * @return The dashboard statistics.
     */
    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('ADMIN')")
    public AdminDashboardStatsDTO getDashboardStats() {
        return adminService.getDashboardStats();
    }

    /**
     * Creates a new admin.
     *
     * @param request The request body containing the new admin's details.
     * @return A response entity with the created admin's data.
     */
    @PostMapping("/create")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> createAdminByAdmin(@RequestBody CreateAdminRequest request) {
        return ResponseEntity.ok(adminService.createAdminByAdmin(request));
    }

    /**
     * Updates an existing admin.
     *
     * @param adminId The ID of the admin to update.
     * @param request The request body with the updated admin details.
     * @return A response entity with the updated admin's data.
     */
    @PutMapping("/update/{adminId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> updateAdmin(
            @PathVariable Long adminId,
            @RequestBody AdminUpdateRequest request) {
        return ResponseEntity.ok(adminService.updateAdminById(adminId, request));
    }

    /**
     * Deletes an admin.
     *
     * @param adminId The ID of the admin to delete.
     * @return A response entity with a confirmation message.
     */
    @DeleteMapping("/delete/{adminId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<String> deleteAdmin(@PathVariable Long adminId) {
        adminService.deleteAdminById(adminId);
        return ResponseEntity.ok("Admin with ID " + adminId + " has been deleted.");
    }

    /**
     * Retrieves an admin by their ID.
     *
     * @param adminId The ID of the admin to retrieve.
     * @return A response entity with the admin's data.
     */
    @GetMapping("/get/{adminId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> getAdminById(@PathVariable Long adminId) {
        return ResponseEntity.ok(adminService.getAdminById(adminId));
    }

    /**
     * Retrieves all admins.
     *
     * @return A response entity with a list of all admins.
     */
    @GetMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdminDTO>> getAllAdmins() {
        return ResponseEntity.ok(adminService.getAllAdmins());
    }

    /**
     * Updates the admin profile with multipart form data.
     *
     * @param userDetails The details of the authenticated admin.
     * @param username The admin's new username.
     * @param email The admin's new email address.
     * @param birthDate The admin's new date of birth (yyyy-MM-dd).
     * @param iphoneNumber The admin's new phone number.
     * @param image An optional new profile image.
     * @return A response entity with the updated admin's data.
     */
    @PutMapping(value = "/profile", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdminDTO> updateAdminProfileForm(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(value = "username",      required = false) String username,
            @RequestParam(value = "email",         required = false) String email,
            @RequestParam(value = "birthDate",     required = false) String birthDate,
            @RequestParam(value = "iphoneNumber",  required = false) String iphoneNumber,
            @RequestPart(value = "image",          required = false) MultipartFile image
    ) {
        String principalEmail = userDetails.getUsername();
        AdminDTO dto = adminService.updateAdminProfileWithForm(
                principalEmail, username, email, birthDate, iphoneNumber, image
        );
        return ResponseEntity.ok(dto);
    }
}
