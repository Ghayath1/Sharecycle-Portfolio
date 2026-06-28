package com.Shrecycle.Sharecycle_backend.dto;

import lombok.*;

import java.time.LocalDate;

/**
 * Data Transfer Object for representing an admin user.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminDTO {
    private Long id;
    private String username;
    private String email;
    private String iphoneNumber;
    private String imageUrl;
    private LocalDate birthDate;
}
