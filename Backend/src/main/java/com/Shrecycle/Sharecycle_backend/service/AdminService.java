package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.dto.AdminDTO;
import com.Shrecycle.Sharecycle_backend.dto.AdminDashboardStatsDTO;
import com.Shrecycle.Sharecycle_backend.dto.AdminUpdateRequest;
import com.Shrecycle.Sharecycle_backend.dto.CreateAdminRequest;
import com.Shrecycle.Sharecycle_backend.entity.Admin;
import com.Shrecycle.Sharecycle_backend.repository.AdminRepository;
import com.Shrecycle.Sharecycle_backend.repository.BicycleRepository;
import com.Shrecycle.Sharecycle_backend.repository.OrderRepository;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Service for admin-related operations.
 */
@Service
@RequiredArgsConstructor
public class AdminService {

    private final AdminRepository adminRepository;
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final BicycleRepository bicycleRepository;
    private final PasswordEncoder passwordEncoder;
    private final FileStorageService fileStorageService;

    /**
     * Creates a new admin.
     *
     * @param dto         The DTO containing the new admin's details.
     * @param rawPassword The raw password for the new admin.
     * @return The created admin's data.
     */
    public AdminDTO createAdmin(AdminDTO dto, String rawPassword) {
        Admin admin = Admin.builder()
                .username(dto.getUsername())
                .email(dto.getEmail())
                .password(passwordEncoder.encode(rawPassword))
                .iphoneNumber(dto.getIphoneNumber())
                .imageUrl(dto.getImageUrl())
                .build();

        Admin saved = adminRepository.save(admin);
        return mapToDTO(saved);
    }

    /**
     * Maps an Admin entity to an AdminDTO.
     *
     * @param admin The Admin entity to map.
     * @return The mapped AdminDTO.
     */
    private AdminDTO mapToDTO(Admin admin) {
        return AdminDTO.builder()
                .id(admin.getId())
                .username(admin.getUsername())
                .email(admin.getEmail())
                .iphoneNumber(admin.getIphoneNumber())
                .imageUrl(admin.getImageUrl())
                .birthDate(admin.getBirthDate())
                .build();
    }

    /**
     * Retrieves dashboard statistics for the admin panel.
     *
     * @return The dashboard statistics.
     */
    public AdminDashboardStatsDTO getDashboardStats() {
        long userCount = userRepository.count();
        long orderCount = orderRepository.count();
        long bicycleCount = bicycleRepository.count();

        double totalIncome = orderRepository.findAll().stream()
                .mapToDouble(order -> order.getTotalPrice())
                .sum();

        return AdminDashboardStatsDTO.builder()
                .userCount(userCount)
                .orderCount(orderCount)
                .bicycleCount(bicycleCount)
                .totalIncome(totalIncome)
                .build();
    }

    /**
     * Creates a new admin.
     *
     * @param request The request containing the new admin's details.
     * @return The created admin's data.
     */
    public AdminDTO createAdminByAdmin(CreateAdminRequest request) {
        Admin admin = Admin.builder()
                .username(request.getUsername())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .iphoneNumber(request.getIphoneNumber())
                .imageUrl(request.getImageUrl())
                .build();

        Admin saved = adminRepository.save(admin);
        return mapToDTO(saved);
    }

    /**
     * Updates an admin's details.
     *
     * @param adminId The ID of the admin to update.
     * @param request The request containing the updated details.
     * @return The updated admin's data.
     */
    public AdminDTO updateAdminById(Long adminId, AdminUpdateRequest request) {
        Admin admin = adminRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin not found"));

        if (request.getUsername() != null) admin.setUsername(request.getUsername());
        if (request.getEmail() != null) admin.setEmail(request.getEmail());
        if (request.getIphoneNumber() != null) admin.setIphoneNumber(request.getIphoneNumber());
        if (request.getImageUrl() != null) admin.setImageUrl(request.getImageUrl());

        Admin updated = adminRepository.save(admin);
        return mapToDTO(updated);
    }

    /**
     * Deletes an admin.
     *
     * @param adminId The ID of the admin to delete.
     */
    public void deleteAdminById(Long adminId) {
        Admin admin = adminRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin not found"));

        adminRepository.delete(admin);
    }

    /**
     * Retrieves an admin by their ID.
     *
     * @param adminId The ID of the admin to retrieve.
     * @return The admin's data.
     */
    public AdminDTO getAdminById(Long adminId) {
        Admin admin = adminRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        return mapToDTO(admin);
    }

    public AdminDTO getAdminByEmail(String email) {
        Admin admin = adminRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        return mapToDTO(admin);
    }

    /**
     * Retrieves all admins.
     *
     * @return A list of all admins.
     */
    public List<AdminDTO> getAllAdmins() {
        return adminRepository.findAll()
                .stream()
                .map(this::mapToDTO)
                .toList();
    }

    /**
     * Updates the admin profile with form data (multipart).
     *
     * @param principalEmail The email of the authenticated admin.
     * @param username The admin's new username.
     * @param emailNew The admin's new email address.
     * @param birthDate The admin's new date of birth (yyyy-MM-dd).
     * @param iphoneNumber The admin's new phone number.
     * @param image An optional new profile image.
     * @return The updated admin's data.
     */
    public AdminDTO updateAdminProfileWithForm(
            String principalEmail,
            String username,
            String emailNew,
            String birthDate,
            String iphoneNumber,
            MultipartFile image
    ) {
        Admin admin = adminRepository.findByEmail(principalEmail)
                .orElseThrow(() -> new RuntimeException("Admin not found"));

        if (username != null && !username.isBlank()) admin.setUsername(username);
        if (emailNew != null && !emailNew.isBlank()) admin.setEmail(emailNew);
        if (birthDate != null && !birthDate.isBlank()) {
            try {
                admin.setBirthDate(LocalDate.parse(birthDate));
            } catch (DateTimeParseException e) {
                throw new RuntimeException("Invalid birth date format. Use yyyy-MM-dd");
            }
        }
        if (iphoneNumber != null && !iphoneNumber.isBlank()) admin.setIphoneNumber(iphoneNumber);

        if (image != null && !image.isEmpty()) {
            try {
                String url = fileStorageService.saveAdminImage(admin.getId(), image);
                if (url != null) admin.setImageUrl(url);
            } catch (IOException e) {
                throw new RuntimeException("Image upload failed: " + e.getMessage(), e);
            }
        }

        Admin saved = adminRepository.save(admin);
        return mapToDTO(saved);
    }
}
