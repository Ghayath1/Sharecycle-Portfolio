package com.Shrecycle.Sharecycle_backend.dto;

import lombok.*;

/**
 * Data Transfer Object for updating an admin's details.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminUpdateRequest {
    private String username;
    private String email;
    private String iphoneNumber;
    private String imageUrl;
}
