package com.Shrecycle.Sharecycle_backend.service;

import com.Shrecycle.Sharecycle_backend.dto.BicycleDTO;
import com.Shrecycle.Sharecycle_backend.dto.BicycleResponseDTO;
import com.Shrecycle.Sharecycle_backend.dto.OrderResponseDTO;
import com.Shrecycle.Sharecycle_backend.entity.Bicycle;
import com.Shrecycle.Sharecycle_backend.entity.User;
import com.Shrecycle.Sharecycle_backend.repository.BicycleRepository;
import com.Shrecycle.Sharecycle_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

/**
 * Service for bicycle-related operations.
 */
@Service
@RequiredArgsConstructor
public class BicycleService {

    private final BicycleRepository bicycleRepository;
    private final UserRepository userRepository;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    /**
     * Creates a new bicycle.
     * @param dto The DTO containing the new bicycle's details.
     * @param ownerEmail The email of the bicycle's owner.
     * @param imageFile An optional image of the bicycle.
     * @return The created bicycle.
     */
    public Bicycle saveBicycle(BicycleDTO dto, String ownerEmail, MultipartFile imageFile) {
        User user = userRepository.findByEmail(ownerEmail)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        Bicycle bike = new Bicycle();
        bike.setName(dto.getName());
        bike.setCity(dto.getCity());
        bike.setPrice(dto.getPrice());
        bike.setDescription(dto.getDescription());
        bike.setAvailableFrom(LocalDate.parse(dto.getAvailableFrom()));
        bike.setOwner(user);

        if (imageFile != null && !imageFile.isEmpty()) {
            String stored = storeImage(imageFile);
            bike.setImageUrl("/uploads/" + stored);
        }

        return bicycleRepository.save(bike);
    }

    /**
     * Updates a bicycle as an admin.
     * @param id The ID of the bicycle to update.
     * @param dto The DTO containing the updated bicycle details.
     * @return The updated bicycle.
     */
    public Bicycle updateBicycle(Long id, BicycleDTO dto) {
        Bicycle bicycle = bicycleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        applyDto(bicycle, dto, true);
        return bicycleRepository.save(bicycle);
    }

    /**
     * Updates a bicycle as a user or admin.
     * @param id The ID of the bicycle to update.
     * @param dto The DTO containing the updated bicycle details.
     * @param requesterEmail The email of the user requesting the update.
     * @param imageFile An optional new image for the bicycle.
     * @return The updated bicycle.
     */
    public Bicycle updateBicycle(Long id, BicycleDTO dto, String requesterEmail, MultipartFile imageFile) {
        Bicycle bicycle = bicycleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        if (bicycle.getOwner() == null || !bicycle.getOwner().getEmail().equalsIgnoreCase(requesterEmail)) {
            throw new SecurityException("You are not authorized to edit this bicycle");
        }

        applyDto(bicycle, dto, false);

        if (imageFile != null && !imageFile.isEmpty()) {
            String stored = storeImage(imageFile);
            bicycle.setImageUrl("/uploads/" + stored);
        }

        return bicycleRepository.save(bicycle);
    }

    public Bicycle updateBicycleAsAdmin(Long id, BicycleDTO dto, String requesterEmail, MultipartFile imageFile) {
        Bicycle bicycle = bicycleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        applyDto(bicycle, dto, false);

        if (imageFile != null && !imageFile.isEmpty()) {
            String stored = storeImage(imageFile);
            bicycle.setImageUrl("/uploads/" + stored);
        }

        return bicycleRepository.save(bicycle);
    }

    /**
     * Retrieves the bicycles of a specific user.
     * @param email The email of the user.
     * @return A list of the user's bicycles.
     */
    public List<Bicycle> getUserBicycles(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return bicycleRepository.findByOwner(user);
    }

    /**
     * Retrieves all bicycles.
     * @return A list of all bicycles.
     */
    public List<Bicycle> getAllBicycles() {
        return bicycleRepository.findAll();
    }

    /**
     * Retrieves a bicycle by its ID.
     * @param id The ID of the bicycle to retrieve.
     * @return The bicycle's data.
     */
    public BicycleResponseDTO getBicycleById(Long id) {
        Bicycle bicycle = bicycleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));
        return toResponseDto(bicycle);
    }

    /**
     * Deletes a bicycle.
     * @param id The ID of the bicycle to delete.
     */
    public void deleteBicycle(Long id) {
        if (!bicycleRepository.existsById(id)) {
            throw new RuntimeException("Bicycle not found with id: " + id);
        }
        bicycleRepository.deleteById(id);
    }

    /**
     * Deletes a bicycle by its ID.
     * @param id The ID of the bicycle to delete.
     * @param requesterEmail The email of the user requesting the deletion.
     */
    public void deleteBicycleById(Long id, String requesterEmail) {
        Bicycle bicycle = bicycleRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Bicycle not found with id: " + id));
        if (bicycle.getOwner() == null || !bicycle.getOwner().getEmail().equalsIgnoreCase(requesterEmail)) {
            throw new SecurityException("You are not authorized to delete this bicycle");
        }
        bicycleRepository.deleteById(id);
    }

    /**
     * Retrieves all bicycles with their owner's information.
     * @return A list of all bicycles with their owner's information.
     */
    public List<Bicycle> getAllBicyclesWithOwnerInfo() {
        List<Bicycle> allBikes = bicycleRepository.findAll();
        for (Bicycle bike : allBikes) {
            if (bike.getOwner() != null) bike.getOwner().getEmail();
        }
        return allBikes;
    }

    /**
     * Applies the data from a BicycleDTO to a Bicycle entity.
     * @param bicycle The Bicycle entity to update.
     * @param dto The DTO containing the new data.
     * @param allowImageFromDto Whether to allow updating the image URL from the DTO.
     */
    private void applyDto(Bicycle bicycle, BicycleDTO dto, boolean allowImageFromDto) {
        bicycle.setName(dto.getName());
        bicycle.setCity(dto.getCity());
        bicycle.setPrice(dto.getPrice());
        bicycle.setDescription(dto.getDescription());
        if (dto.getAvailableFrom() != null && !dto.getAvailableFrom().isBlank()) {
            bicycle.setAvailableFrom(LocalDate.parse(dto.getAvailableFrom()));
        }
        if (allowImageFromDto && dto.getImageUrl() != null && !dto.getImageUrl().isBlank()) {
            String val = dto.getImageUrl();
            if (!val.startsWith("/uploads/") && !val.startsWith("http")) {
                val = "/uploads/" + val;
            }
            bicycle.setImageUrl(val);
        }
    }

    /**
     * Converts a Bicycle entity to a BicycleResponseDTO.
     * @param bicycle The Bicycle entity to convert.
     * @return The converted BicycleResponseDTO.
     */
    public BicycleResponseDTO toResponseDto(Bicycle bicycle) {
        BicycleResponseDTO dto = new BicycleResponseDTO();
        dto.setId(bicycle.getId());
        dto.setName(bicycle.getName());
        dto.setCity(bicycle.getCity());
        dto.setPrice(bicycle.getPrice());
        dto.setAvailableFrom(bicycle.getAvailableFrom() != null ? bicycle.getAvailableFrom().toString() : null);
        dto.setDescription(bicycle.getDescription());
        // Prepend the base URL to the image path
        String imageUrl = bicycle.getImageUrl();
        if (imageUrl != null && !imageUrl.isBlank() && imageUrl.startsWith("/uploads")) {
            String fullImageUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path(imageUrl)
                    .toUriString();
            dto.setImageUrl(fullImageUrl);
        } else {
            dto.setImageUrl(imageUrl); // Keep as is if it's already a full URL or null
        }
        dto.setOwnerEmail(bicycle.getOwner() != null ? bicycle.getOwner().getEmail() : null);
        return dto;
    }

    /**
     * Converts a list of Bicycle entities to a list of BicycleResponseDTOs.
     * @param bicycles The list of Bicycle entities to convert.
     * @return The converted list of BicycleResponseDTOs.
     */
    public List<BicycleResponseDTO> toResponseDtoList(List<Bicycle> bicycles) {
        return bicycles.stream().map(this::toResponseDto).collect(Collectors.toList());
    }

    /**
     * Stores an image file.
     * @param file The image file to store.
     * @return The filename of the stored image.
     */
    private String storeImage(MultipartFile file) {
        try {
            Path dir = Paths.get(uploadDir);
            Files.createDirectories(dir);

            String original = Paths.get(file.getOriginalFilename()).getFileName().toString();
            String sanitized = original.replaceAll("[\\s]+", "_");
            String filename = System.currentTimeMillis() + "_" + sanitized;

            Files.copy(file.getInputStream(), dir.resolve(filename), REPLACE_EXISTING);
            return filename;
        } catch (Exception e) {
            throw new RuntimeException("Could not store file", e);
        }
    }

    /**
     * Calculates the total price of an order.
     * @param bikeId The ID of the bicycle being ordered.
     * @param dateFrom The start date of the rental period.
     * @param dateTo The end date of the rental period.
     * @return An OrderResponseDTO containing the calculated total price and rental days.
     */
    public OrderResponseDTO calculateOrderTotal(Long bikeId, String dateFrom, String dateTo) {
        Bicycle bicycle = bicycleRepository.findById(bikeId)
                .orElseThrow(() -> new RuntimeException("Bicycle not found"));

        LocalDate from = LocalDate.parse(dateFrom);
        LocalDate to = LocalDate.parse(dateTo);
        long days = ChronoUnit.DAYS.between(from, to);
        if (days < 1) throw new IllegalArgumentException("Rental period must be at least 1 day");

        double totalPrice = bicycle.getPrice() * days;

        OrderResponseDTO response = new OrderResponseDTO();
        response.setRentalDays(days);
        response.setTotalPrice(totalPrice);
        return response;
    }
}
