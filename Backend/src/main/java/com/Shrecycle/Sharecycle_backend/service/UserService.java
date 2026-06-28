package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.dto.AdminUpdateUserRequest;
import com.Shrecycle.Sharecycle_backend.dto.UpdateUserRequest;
import com.Shrecycle.Sharecycle_backend.dto.UserDTO;
import com.Shrecycle.Sharecycle_backend.dto.UserProfileDTO;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Service for user-related operations.
 */
@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final ModelMapper modelMapper;
    private final FileStorageService fileStorageService;

    /**
     * Retrieves the current user as a full UserDTO.
     * @param usernameOrEmail The username or email of the user.
     * @return The user's data.
     */
    public UserDTO getCurrentUser(String usernameOrEmail) {
        User user = userRepository.findByEmail(usernameOrEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return modelMapper.map(user, UserDTO.class);
    }

    /**
     * Retrieves a user by their email address.
     * @param email The email address of the user.
     * @return The user's data.
     */
    public UserDTO getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));
        return new UserDTO(user);
    }

    /**
     * Updates the profile of the authenticated user.
     * @param email The email of the user to update.
     * @param request The request containing the updated user details.
     * @return The updated user's data.
     */
    public UserDTO updateProfile(String email, UpdateUserRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (request.getName() != null && !request.getName().isBlank()) {
            user.setName(request.getName());
        }
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            user.setEmail(request.getEmail());
        }
        if (request.getBirthDate() != null && !request.getBirthDate().isBlank()) {
            try {
                user.setBirthDate(LocalDate.parse(request.getBirthDate()));
            } catch (DateTimeParseException e) {
                throw new RuntimeException("Invalid birth date format. Use yyyy-MM-dd");
            }
        }

        if (request.getIphoneNumber() != null && !request.getIphoneNumber().isBlank()) {
            user.setIphoneNumber(request.getIphoneNumber());
        }
        if (request.getCity() != null && !request.getCity().isBlank()) {
            user.setCity(request.getCity());
        }
        if (request.getImageUrl() != null && !request.getImageUrl().isBlank()) {
            user.setImageUrl(request.getImageUrl());
        }
        if (request.getIdCardNumber() != null && !request.getIdCardNumber().isBlank()) {
            user.setIdCardNumber(request.getIdCardNumber());
        }
        if (request.getIdCardImageUrl() != null && !request.getIdCardImageUrl().isBlank()) {
            user.setIdCardImageUrl(request.getIdCardImageUrl());
        }

        User updated = userRepository.save(user);
        return new UserDTO(updated);
    }

    /**
     * Updates the profile of the authenticated user with form data.
     * @param principalEmail The email of the authenticated user.
     * @param name The user's new name.
     * @param emailNew The user's new email address.
     * @param birthDate The user's new date of birth (yyyy-MM-dd).
     * @param iphoneNumber The user's new phone number.
     * @param city The user's new city.
     * @param idCardNumber The user's new ID card number.
     * @param image An optional new profile image.
     * @return The updated user's data.
     */
    public UserDTO updateProfileWithForm(
            String principalEmail,
            String name,
            String emailNew,
            String birthDate,
            String iphoneNumber,
            String city,
            String idCardNumber,
            MultipartFile image
    ) {
        User user = userRepository.findByEmail(principalEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        if (name != null && !name.isBlank()) user.setName(name);
        if (emailNew != null && !emailNew.isBlank()) user.setEmail(emailNew);
        if (birthDate != null && !birthDate.isBlank()) {
            try {
                user.setBirthDate(LocalDate.parse(birthDate));
            } catch (DateTimeParseException e) {
                throw new RuntimeException("Invalid birth date format. Use yyyy-MM-dd");
            }
        }
        if (iphoneNumber != null && !iphoneNumber.isBlank()) user.setIphoneNumber(iphoneNumber);
        if (city != null && !city.isBlank()) user.setCity(city);
        if (idCardNumber != null && !idCardNumber.isBlank()) user.setIdCardNumber(idCardNumber);

        if (image != null && !image.isEmpty()) {
            try {
                String url = fileStorageService.saveUserImage(user.getId(), image);
                if (url != null) user.setImageUrl(url);
            } catch (IOException e) {
                throw new RuntimeException("Image upload failed: " + e.getMessage(), e);
            }
        }

        User saved = userRepository.save(user);
        return new UserDTO(saved);
    }

    /**
     * Retrieves the basic profile of a user.
     * @param email The email of the user.
     * @return The user's basic profile data.
     */
    public UserProfileDTO getUserProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return UserProfileDTO.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .iphoneNumber(user.getIphoneNumber())
                .city(user.getCity())
                .imageUrl(user.getImageUrl())
                .age(user.getAge())
                .idCardNumber(user.getIdCardNumber())
                .build();
    }

    /**
     * Retrieves a list of all regular users.
     * @return A list of all users with the 'USER' role.
     */
    public List<UserDTO> getAllRegularUsers() {
        List<User> users = userRepository.findByRole("USER");
        return users.stream().map(UserDTO::new).toList();
    }

    /**
     * Updates a user's details as an admin.
     * @param userId The ID of the user to update.
     * @param request The request containing the updated user details.
     * @return The updated user's data.
     */
    public UserDTO updateUserByAdmin(Long userId, AdminUpdateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getName() != null) user.setName(request.getName());
        if (request.getEmail() != null) user.setEmail(request.getEmail());
        if (request.getBirthDate() != null) user.setBirthDate(request.getBirthDate());
        if (request.getIphoneNumber() != null) user.setIphoneNumber(request.getIphoneNumber());
        if (request.getCity() != null) user.setCity(request.getCity());
        if (request.getImageUrl() != null) user.setImageUrl(request.getImageUrl());
        if (request.getIdCardNumber() != null) user.setIdCardNumber(request.getIdCardNumber());
        if (request.getIdCardImageUrl() != null) user.setIdCardImageUrl(request.getIdCardImageUrl());
        if (request.getRole() != null) user.setRole(request.getRole());

        userRepository.save(user);
        return new UserDTO(user);
    }

    /**
     * Deletes a user as an admin.
     * @param userId The ID of the user to delete.
     */
    public void deleteUserByAdmin(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        userRepository.delete(user);
    }
}
