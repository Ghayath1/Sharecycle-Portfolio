package com.Shrecycle.Sharecycle_backend.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.Period;

/**
 * Represents an admin user in the system.
 */
@Entity
@Table(
        name = "admins",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = "email"),
                @UniqueConstraint(columnNames = "username")
        }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Admin {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String username;

    @Column(nullable = false, unique = true)
    private String email;

    private String password;
    private String iphoneNumber;
    private String imageUrl;
    private LocalDate birthDate;
    @Transient
    public Integer getAge() {
        return (birthDate == null) ? null : Period.between(birthDate, LocalDate.now()).getYears();
    }
}
