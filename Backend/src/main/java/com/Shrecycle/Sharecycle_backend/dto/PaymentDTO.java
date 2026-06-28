package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for payment information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaymentDTO {
    private Long id;
    private Long orderId;
    private PaymentStatus status;
    private String paypalOrderId;
    private String authorizationId;
    private String captureId;
    private Double amount;
}
