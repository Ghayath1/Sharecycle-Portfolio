package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for User entities.
 */
public interface UserRepository extends JpaRepository<User, Long> {
    /**
     * Finds a user by their email address.
     * @param email The email address to search for.
     * @return An Optional containing the user if found, or an empty Optional otherwise.
     */
    Optional<User> findByEmail(String email);

    /**
     * Checks if a user with the given email address exists.
     * @param email The email address to check.
     * @return true if a user with the email exists, false otherwise.
     */
    boolean existsByEmail(String email);

    /**
     * Finds all users with a specific role.
     * @param role The role to search for.
     * @return A list of users with the specified role.
     */
    List<User> findByRole(String role);
    
    /**
     * Finds a user by their FCM token.
     * @param fcmToken The FCM token to search for.
     * @return An Optional containing the user if found, or an empty Optional otherwise.
     */
    Optional<User> findByFcmToken(String fcmToken);
}
