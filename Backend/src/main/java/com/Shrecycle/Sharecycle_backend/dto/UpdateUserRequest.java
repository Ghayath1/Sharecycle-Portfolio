package com.Shrecycle.Sharecycle_backend.dto;

import lombok.Data;

/**
 * Data Transfer Object for updating a user's profile.
 */
@Data
public class UpdateUserRequest {
    private String name;
    private String email;
    private String birthDate;      // yyyy-MM-dd

    // 🔹 NEW optional fields (partial update allowed)
    private String iphoneNumber;
    private String city;
    private String imageUrl;
    private String idCardNumber;
    private String idCardImageUrl;
}
