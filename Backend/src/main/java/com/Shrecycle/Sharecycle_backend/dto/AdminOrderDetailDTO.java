package com.Shrecycle.Sharecycle_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Data Transfer Object for representing the detailed view of an order for an admin.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminOrderDetailDTO {
    private Long orderId;

    // Bicycle
    private Long bikeId;
    private String bikeName;
    private String bikeImageUrl;
    private double bikePrice;
    private String bikeCity;
    private String bikeDate;

    // Customer
    private String customerName;
    private Long customerId;
    private String customerProfileImage;

    // Vendor
    private String vendorName;
    private Long vendorId;
    private String vendorProfileImage;

    // Order
    private String dateFrom;
    private String dateTo;
    private String paymentMethod;

    private LocalDate orderDate;
}
