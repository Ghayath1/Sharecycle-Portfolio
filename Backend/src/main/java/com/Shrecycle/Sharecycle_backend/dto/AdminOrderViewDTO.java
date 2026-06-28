package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import lombok.*;

import java.time.LocalDate;

/**
 * Data Transfer Object for representing a compact view of an order for an admin.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminOrderViewDTO {
    private Long orderId;
    private String customerName;
    private Long vendorId;
    private LocalDate dateFrom;
    private LocalDate dateTo;
    private LocalDate orderDate;
    private Double price;
    private OrderStatus status;
}
