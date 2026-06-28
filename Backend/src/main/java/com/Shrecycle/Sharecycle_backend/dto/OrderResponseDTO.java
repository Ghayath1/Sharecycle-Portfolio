package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import lombok.Data;
import java.time.LocalDate;

/**
 * Data Transfer Object for representing an order in a response.
 */
@Data
public class OrderResponseDTO {
    private Long orderId;

    // 🔹 Bike info
    private Long bicycleId;
    private String bikeName;
    private String bikeImageUrl;
    private Double pricePerDay;

    // 🔹 User info
    private UserDTO renter;
    private UserDTO owner;

    // 🔹 Dates & price
    private String dateFrom;  // yyyy-MM-dd
    private String dateTo;    // yyyy-MM-dd
    private long rentalDays;
    private double totalPrice;

    // 🔹 Optional metadata
    private LocalDate orderDate;

    private OrderStatus orderStatus;
}
