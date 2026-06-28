package com.Shrecycle.Sharecycle_backend.entity;

import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Represents an order for a bicycle rental.
 */
@Entity
@Table(name = "orders") // Avoid conflict with SQL keyword "ORDER"
@Getter
@Setter
@EqualsAndHashCode(callSuper = true)
public class Order extends TimeStampedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    private User renter;

    @ManyToOne(optional = false)
    private Bicycle bicycle;

    private LocalDate dateFrom;
    private LocalDate dateTo;

    private long rentalDays;
    private double totalPrice;

    @Enumerated(EnumType.STRING)
    private OrderStatus status = OrderStatus.PENDING;

    @OneToOne(cascade = CascadeType.ALL)
    private Payment payment = new Payment();
}
