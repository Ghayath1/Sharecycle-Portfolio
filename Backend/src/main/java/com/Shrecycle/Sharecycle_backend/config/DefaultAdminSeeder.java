package com.Shrecycle.Sharecycle_backend.config;

import com.Shrecycle.Sharecycle_backend.entity.Admin;
import com.Shrecycle.Sharecycle_backend.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

/**
 * Seeds the database with a default admin user if one does not already exist.
 * This class runs on application startup.
 */
@Component
@RequiredArgsConstructor
public class DefaultAdminSeeder implements CommandLineRunner {

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Executes the seeding process.
     * Checks if a default admin exists by email or username and creates one if not.
     *
     * @param args Command line arguments (not used).
     */
    @Override
    public void run(String... args) {
        String email = "ghayath@admin.com";  // ✅ ثابت
        String username = "SuperAdmin";
        String password = "Ghayath";

        boolean exists = adminRepository.findByEmail(email).isPresent()
                || adminRepository.findByUsername(username).isPresent();

        if (!exists) {
            Admin admin = Admin.builder()
                    .username(username)
                    .email(email)
                    .password(passwordEncoder.encode(password))
                    .iphoneNumber("01004570585")
                    .imageUrl("/uploads/1756064814547_scaled_1000000034.jpg")
                    .birthDate(LocalDate.of(1995, 11, 1))
                    .build();

            adminRepository.save(admin);
            System.out.println("✅ Default admin created: " + email);
        } else {
            System.out.println("ℹ️ Default admin already exists. Skipping seeding.");
        }
    }
}
