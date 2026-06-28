package com.Shrecycle.Sharecycle_backend.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.*;

import java.time.LocalDate;

/**
 * Data Transfer Object for an admin to update a user's details.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL) // omit nulls from JSON
public class AdminUpdateUserRequest {


    private String name;


    private String email;

    private LocalDate birthDate;

    private String iphoneNumber;
    private String role;
    private String city;
    private String imageUrl;
    private String idCardNumber;

    private String idCardImageUrl;
}
