package com.Shrecycle.Sharecycle_backend.dto;

import lombok.Data;


/**
 * Data Transfer Object for representing a bicycle.
 */
@Data
public class BicycleDTO {

    private String name;

    private String city;

    private double price;

    private String availableFrom;
    private String description;

    private String imageUrl; // Optional image filename or path

    private Long ownerId;    // Optional (used only by Admin if needed)
}
