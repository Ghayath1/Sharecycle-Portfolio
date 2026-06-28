package com.Shrecycle.Sharecycle_backend.dto;

import lombok.*;

/**
 * Data Transfer Object for representing admin dashboard statistics.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminDashboardStatsDTO {
    private long userCount;
    private long orderCount;
    private long bicycleCount;
    private double totalIncome;
}
