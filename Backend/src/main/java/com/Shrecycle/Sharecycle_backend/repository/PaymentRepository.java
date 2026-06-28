package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.Order;
import com.Shrecycle.Sharecycle_backend.entity.Payment;
import com.Shrecycle.Sharecycle_backend.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repository for Order entities.
 */
public interface PaymentRepository extends JpaRepository<Payment, Long> {

}
