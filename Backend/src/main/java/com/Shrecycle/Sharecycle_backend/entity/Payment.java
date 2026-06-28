package com.Shrecycle.Sharecycle_backend.entity;

import com.Shrecycle.Sharecycle_backend.enums.PaymentStatus;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Setter
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class Payment extends TimeStampedEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Enumerated(EnumType.STRING)
    private PaymentStatus status = PaymentStatus.INITIALIZED;

    private String paypalOrderId;
    private String authorizationId;
    private String captureId;
    @Column(columnDefinition = "TEXT")
    private String paymentHistory = "[]";
}
