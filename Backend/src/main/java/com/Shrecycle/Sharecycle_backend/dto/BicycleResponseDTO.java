package com.Shrecycle.Sharecycle_backend.dto;

import lombok.Data;

/**
 * Data Transfer Object for representing a bicycle in a response.
 */
@Data
public class BicycleResponseDTO {

    private Long id;              // Unique identifier
    private String name;          // Name of the bicycle
    private String city;          // City where the bike is located
    private double price;         // Price per day
    private String availableFrom;          // Available date or creation date (as string)
    private String description;   // Description of the bike
    private String imageUrl;      // Optional image file name or URL
    private String ownerEmail;    // Email of the owner (admin view)
}
