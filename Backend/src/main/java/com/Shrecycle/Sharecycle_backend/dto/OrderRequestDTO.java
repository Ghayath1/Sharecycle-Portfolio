package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.repository.BicycleRepository;
import lombok.Data;

/**
 * Data Transfer Object for creating or updating an order.
 */
@Data
public class OrderRequestDTO {
    private Long bicycleId;
    private String dateFrom;
    private String dateTo;
}
