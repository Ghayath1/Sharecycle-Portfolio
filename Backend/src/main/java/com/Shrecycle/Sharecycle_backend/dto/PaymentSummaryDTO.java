package com.Shrecycle.Sharecycle_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for payment summary information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentSummaryDTO {
    private Double totalIncome;
}
