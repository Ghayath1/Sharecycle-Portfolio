package com.Shrecycle.Sharecycle_backend.dto;

import lombok.*;

/**
 * Data Transfer Object for representing a user's profile.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileDTO {
    private Long id;
    private String name;
    private String email;
    private String iphoneNumber;

    // 🔹 NEW
    private String city;
    private String imageUrl;
    private Integer age;          // computed
    private String idCardNumber;  // if you want to show to the user; mask if needed
}
