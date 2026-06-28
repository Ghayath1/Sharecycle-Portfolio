package com.Shrecycle.Sharecycle_backend.dto;

/**
 * Data Transfer Object for a user signup request.
 */
public class SignupRequest {
    private String firstName;
    private String lastName;
    private String email;
    private String password;
    /** ISO format: yyyy-MM-dd */
    private String birthDate;

    // Optional extras
    private String iphoneNumber;
    private String city;
    /** URL or storage path for profile image */
    private String imageUrl;
    /** National ID / passport number (store carefully) */
    private String idCardNumber;
    /** URL or storage path for the scanned ID image */
    private String idCardImageUrl;

    // ===== Getters / Setters =====
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getBirthDate() { return birthDate; }
    public void setBirthDate(String birthDate) { this.birthDate = birthDate; }

    public String getIphoneNumber() { return iphoneNumber; }
    public void setIphoneNumber(String iphoneNumber) { this.iphoneNumber = iphoneNumber; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getIdCardNumber() { return idCardNumber; }
    public void setIdCardNumber(String idCardNumber) { this.idCardNumber = idCardNumber; }

    public String getIdCardImageUrl() { return idCardImageUrl; }
    public void setIdCardImageUrl(String idCardImageUrl) { this.idCardImageUrl = idCardImageUrl; }
}
