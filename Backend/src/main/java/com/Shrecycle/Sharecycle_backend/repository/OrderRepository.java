package com.Shrecycle.Sharecycle_backend.repository;

import com.Shrecycle.Sharecycle_backend.entity.Bicycle;
import com.Shrecycle.Sharecycle_backend.entity.Order;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * Repository for Order entities.
 */
public interface OrderRepository extends JpaRepository<Order, Long> {
    /**
     * Finds all orders placed by a specific user.
     *
     * @param user The user who placed the orders.
     * @return A list of orders placed by the user.
     */
    List<Order> findByRenter(User user);

    /**
     * Finds all orders for bicycles owned by a specific user.
     *
     * @param owner The user who owns the bicycles.
     * @return A list of orders for bicycles owned by the user.
     */
    List<Order> findByBicycleOwner(User owner);

    Optional<Order> findByPayment_PaypalOrderId(String paymentPaypalOrderId);

    List<Order> findByBicycleAndStatus(Bicycle bicycle, OrderStatus status);

    List<Order> findByBicycleAndStatusAndPaymentStatus(Bicycle bicycle, OrderStatus orderStatus, PaymentStatus paymentStatus);

    List<Order> findAllByStatus(OrderStatus status, Sort id);
}
