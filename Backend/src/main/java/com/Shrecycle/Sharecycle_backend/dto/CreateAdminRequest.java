package com.Shrecycle.Sharecycle_backend.dto;

import lombok.*;

/**
 * Data Transfer Object for creating a new admin.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateAdminRequest {
    private String username;
    private String email;
    private String password;
    private String iphoneNumber;
    private String imageUrl;
}
