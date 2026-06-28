package com.Shrecycle.Sharecycle_backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDate;

/**
 * Represents a bicycle in the system.
 */
@Entity
@Data
public class Bicycle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String city;
    private double price;
    private LocalDate availableFrom;
    private String description;
    private String imageUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties({"bicycles", "password"}) // ✅ Avoid cycle and hide password
    private User owner;
}
