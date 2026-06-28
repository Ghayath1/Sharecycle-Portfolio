package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.Admin;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Repository for Admin entities.
 */
public interface AdminRepository extends JpaRepository<Admin, Long> {
    /**
     * Finds an admin by their email address.
     * @param email The email address to search for.
     * @return An Optional containing the admin if found, or an empty Optional otherwise.
     */
    Optional<Admin> findByEmail(String email);

    /**
     * Finds an admin by their username.
     * @param username The username to search for.
     * @return An Optional containing the admin if found, or an empty Optional otherwise.
     */
    Optional<Admin> findByUsername(String username);
}
