package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.dto.LoginRequest;
import com.Shrecycle.Sharecycle_backend.dto.LoginResponse;
import com.Shrecycle.Sharecycle_backend.dto.SignupRequest;
import com.Shrecycle.Sharecycle_backend.dto.UserDTO;
import com.Shrecycle.Sharecycle_backend.entity.Admin;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.dto.ForgotPasswordRequest;
import com.Shrecycle.Sharecycle_backend.dto.ResetPasswordRequest;
import com.Shrecycle.Sharecycle_backend.repository.AdminRepository;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import com.Shrecycle.Sharecycle_backend.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Objects;
import java.util.Random;

/**
 * Service for authentication-related operations.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final AdminRepository adminRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final FileStorageService fileStorageService;
    private final EmailService emailService;

    /**
     * Authenticates a user and returns a login response.
     *
     * @param request The login request containing the user's credentials.
     * @return A response containing the JWT and user details.
     */
    public LoginResponse login(LoginRequest request) {
        final String email = request.getEmail();
        final String raw = request.getPassword();

        // Try to authenticate as an admin first
        Admin admin = adminRepository.findByEmail(email).orElse(null);
        if (admin != null) {
            if (!passwordEncoder.matches(raw, admin.getPassword())) {
                throw new RuntimeException("Invalid email or password");
            }

            UserDetails principal = new org.springframework.security.core.userdetails.User(
                    admin.getEmail(),
                    admin.getPassword(),
                    List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
            );

            String token = jwtUtil.generateToken(principal);
            return new LoginResponse(token, "success", null);
        }

        // If not an admin, try to authenticate as a user
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        if (!passwordEncoder.matches(raw, user.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        String role = (user.getRole() == null || user.getRole().isBlank()) ? "USER" : user.getRole();

        UserDetails principal = new org.springframework.security.core.userdetails.User(
                user.getEmail(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_" + role))
        );

        String token = jwtUtil.generateToken(principal);
        return new LoginResponse(token, "success", new UserDTO(user));
    }

    /**
     * Registers a new user.
     *
     * @param request The signup request containing the new user's details.
     * @return The created user's data.
     */
    public UserDTO register(SignupRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email is already taken.");
        }

        LocalDate birthDate;
        try {
            birthDate = LocalDate.parse(request.getBirthDate());
        } catch (DateTimeParseException e) {
            throw new RuntimeException("Invalid birth date format. Use yyyy-MM-dd");
        }

        String first = safeTrim(request.getFirstName());
        String last = safeTrim(request.getLastName());
        String fullName = (first + " " + last).trim().replaceAll("\\s+", " ");

        User user = new User();
        user.setName(fullName);
        user.setEmail(safeTrim(request.getEmail()));
        user.setUsername((first + "." + last).toLowerCase());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setBirthDate(birthDate);
        user.setRole("USER");

        try {
            user.setIphoneNumber(safeTrim(request.getIphoneNumber()));
        } catch (Exception ignored) {
        }
        try {
            user.setCity(safeTrim(request.getCity()));
        } catch (Exception ignored) {
        }
        try {
            user.setImageUrl(safeTrim(request.getImageUrl()));
        } catch (Exception ignored) {
        }
        try {
            user.setIdCardNumber(safeTrim(request.getIdCardNumber()));
        } catch (Exception ignored) {
        }
        try {
            user.setIdCardImageUrl(safeTrim(request.getIdCardImageUrl()));
        } catch (Exception ignored) {
        }

        User saved = userRepository.save(user);
        return new UserDTO(saved);
    }

    /**
     * Registers a new user with an optional profile image.
     *
     * @param firstName The user's first name.
     * @param lastName  The user's last name.
     * @param email     The user's email address.
     * @param password  The user's password.
     * @param birthDate The user's date of birth (yyyy-MM-dd).
     * @param image     An optional profile image.
     * @return The created user's data.
     */
    public UserDTO registerMultipart(String firstName,
                                     String lastName,
                                     String email,
                                     String password,
                                     String birthDate,
                                     MultipartFile image) {
        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("Email is already taken.");
        }

        LocalDate dob;
        try {
            dob = LocalDate.parse(birthDate);
        } catch (DateTimeParseException e) {
            throw new RuntimeException("Invalid birth date format. Use yyyy-MM-dd");
        }

        String first = safeTrim(firstName);
        String last = safeTrim(lastName);
        String fullName = (first + " " + last).trim().replaceAll("\\s+", " ");

        User user = new User();
        user.setName(fullName);
        user.setEmail(safeTrim(email));
        user.setUsername((first + "." + last).toLowerCase());
        user.setPassword(passwordEncoder.encode(password));
        user.setBirthDate(dob);
        user.setRole("USER");

        User saved = userRepository.save(user);

        try {
            if (image != null && !image.isEmpty()) {
                String url = fileStorageService.saveUserImage(saved.getId(), image);
                if (url != null) {
                    saved.setImageUrl(url);
                    saved = userRepository.save(saved);
                }
            }
        } catch (Exception ex) {
            throw new RuntimeException("Image upload failed: " + ex.getMessage(), ex);
        }

        return new UserDTO(saved);
    }

    /**
     * Safely trims a string.
     *
     * @param s The string to trim.
     * @return The trimmed string, or null if the input was null.
     */
    private String safeTrim(String s) {
        return s == null ? null : s.trim();
    }

    public void forgotPassword(ForgotPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        String otp = generateOtp();
        user.setOtp(otp);
        user.setOtpExpiryTime(LocalDateTime.now().plusMinutes(10));
        user.setOtpAttemptCount(0);
        userRepository.save(user);

        emailService.sendOtpEmail(user.getEmail(), otp);
    }

    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (Objects.isNull(user.getOtp())) {
            throw new RuntimeException("Please request an OTP before resetting the password.");
        }

        if (user.getOtpAttemptCount() >= 5) {
            throw new RuntimeException("Maximum OTP attempts reached. Please request a new OTP.");
        }

        if (!user.getOtp().equals(request.getOtp())) {
            user.setOtpAttemptCount(user.getOtpAttemptCount() + 1);
            userRepository.save(user);
            throw new RuntimeException("Invalid OTP");
        }

        if (user.getOtpExpiryTime().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("OTP has expired");
        }

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        user.setOtp(null);
        user.setOtpExpiryTime(null);
        user.setOtpAttemptCount(null);
        userRepository.save(user);
    }

    private String generateOtp() {
        return String.format("%06d", new Random().nextInt(999999));
    }
}
