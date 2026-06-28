package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.Bicycle;
import com.Shrecycle.Sharecycle_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repository for Bicycle entities.
 */
public interface BicycleRepository extends JpaRepository<Bicycle, Long> {
    /**
     * Finds all bicycles owned by a specific user.
     * @param owner The user who owns the bicycles.
     * @return A list of bicycles owned by the user.
     */
    List<Bicycle> findByOwner(User owner);
}
