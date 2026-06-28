package com.Shrecycle.Sharecycle_backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.ArrayList;
import java.util.List;

/**
 * Represents a user in the system.
 */
@Entity
@Data
@Table(name = "users")
public class User {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    @Column(unique = true)
    private String email;

    private String username;

    private String password;

    private LocalDate birthDate;

    private String role;                 // USER / ADMIN

    private String iphoneNumber;         // phone

    // 🔹 NEW FIELDS
    private String city;
    private String imageUrl;             // profile photo (URL or path)
    private String idCardNumber;         // national ID / passport
    private String idCardImageUrl;       // optional scan URL

    @OneToMany(mappedBy = "owner", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude @EqualsAndHashCode.Exclude
    @JsonIgnore
    private List<Bicycle> bicycles = new ArrayList<>();

    // 🔹 Computed, not stored
    @Transient
    public Integer getAge() {
        return (birthDate == null) ? null : Period.between(birthDate, LocalDate.now()).getYears();
    }

    private String otp;
    private LocalDateTime otpExpiryTime;
    private Integer otpAttemptCount;
    
    // FCM token for push notifications
    @Column(length = 500)
    private String fcmToken;
    
    private String deviceId; // Optional: track multiple devices
}
