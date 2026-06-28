package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.dto.PaymentDTO;
import com.Shrecycle.Sharecycle_backend.dto.PaymentSummaryDTO;
import com.Shrecycle.Sharecycle_backend.service.PaymentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Controller for payment-related operations.
 * Provides endpoints for retrieving payment information and summaries.
 * All endpoints require ADMIN role.
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentController {

    private final PaymentService paymentService;

    /**
     * Retrieves all payments with their associated order information.
     * @return A response entity with a list of all payments.
     */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<PaymentDTO>> getAllPayments() {
        return ResponseEntity.ok(paymentService.getAllPayments());
    }

    /**
     * Retrieves a summary of total income from all captured payments.
     * @return A response entity with the payment summary.
     */
    @GetMapping("/summary")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PaymentSummaryDTO> getPaymentSummary() {
        return ResponseEntity.ok(paymentService.getPaymentSummary());
    }
}
