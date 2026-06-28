package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.enums.OrderStatus;
import lombok.Data;

/**
 * Data Transfer Object for representing an order from the perspective of a bicycle owner.
 */
@Data
public class OrderResponseForOwnerDTO {
    private Long orderId;
    private UserDTO renter;
    private UserDTO owner;
    private String dateFrom;
    private String dateTo;
    private long rentalDays;
    private double totalPrice;
    private String bikeName;
    private Long bicycleId;
    private String bikeImageUrl;
    private OrderStatus orderStatus;
}
