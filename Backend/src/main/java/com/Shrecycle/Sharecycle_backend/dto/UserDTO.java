package com.Shrecycle.Sharecycle_backend.dto;

import com.Shrecycle.Sharecycle_backend.entity.User;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
public class UserDTO {
    private Long id;
    private String name;
    private String email;
    private LocalDate birthDate;
    private String iphoneNumber;
    private String role;

    // 🔹 NEW
    private String city;
    private String imageUrl;
    private Integer age;           // computed on the fly
    private String idCardNumber;   // consider masking if you don't want to expose fully
    private String idCardImageUrl;

    public UserDTO(Long id, String name, String email, LocalDate birthDate,
                   String iphoneNumber, String role, String city, String imageUrl,
                   Integer age, String idCardNumber, String idCardImageUrl) {
        this.id = id; this.name = name; this.email = email; this.birthDate = birthDate;
        this.iphoneNumber = iphoneNumber; this.role = role;
        this.city = city; this.imageUrl = imageUrl; this.age = age;
        this.idCardNumber = idCardNumber; this.idCardImageUrl = idCardImageUrl;
    }

    public UserDTO(User user) {
        this.id = user.getId();
        this.name = user.getName();
        this.email = user.getEmail();
        this.birthDate = user.getBirthDate();
        this.iphoneNumber = user.getIphoneNumber();
        this.role = user.getRole();
        this.city = user.getCity();
        this.imageUrl = user.getImageUrl();
        this.age = user.getAge();
        this.idCardNumber = user.getIdCardNumber();
        this.idCardImageUrl = user.getIdCardImageUrl();
    }
}
