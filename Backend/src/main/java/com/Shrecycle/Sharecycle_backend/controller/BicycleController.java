package com.Shrecycle.Sharecycle_backend.controller;

import com.Shrecycle.Sharecycle_backend.ResponseException;
import com.Shrecycle.Sharecycle_backend.dto.BicycleDTO;
import com.Shrecycle.Sharecycle_backend.dto.BicycleResponseDTO;
import com.Shrecycle.Sharecycle_backend.dto.OrderRequestDTO;
import com.Shrecycle.Sharecycle_backend.dto.OrderResponseDTO;
import com.Shrecycle.Sharecycle_backend.entity.Bicycle;
import com.Shrecycle.Sharecycle_backend.service.BicycleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Controller for bicycle-related operations.
 * Provides endpoints for creating, retrieving, updating, and deleting bicycles,
 * as well as managing bicycle orders.
 */
@RestController
@RequestMapping("/api/bicycles")
@RequiredArgsConstructor
public class BicycleController {

    private final BicycleService bicycleService;

    /**
     * Adds a new bicycle.
     *
     * @param userDetails   The details of the authenticated user.
     * @param name          The name of the bicycle.
     * @param city          The city where the bicycle is located.
     * @param price         The price per day for renting the bicycle.
     * @param availableFrom The availableFrom the bicycle is available from.
     * @param description   A description of the bicycle.
     * @param imageFile     An optional image of the bicycle.
     * @return A response entity with the created bicycle's data.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<BicycleResponseDTO> addBicycle(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String name,
            @RequestParam String city,
            @RequestParam double price,
            @RequestParam String availableFrom,
            @RequestParam String description,
            @RequestParam(name = "imageUrl", required = false) MultipartFile imageFile
    ) throws ResponseException {

        try {
            LocalDate.parse(availableFrom);
        } catch (DateTimeParseException e) {
            throw new ResponseException("Bad Date format, use: YYYY-MM-DD", HttpStatus.BAD_REQUEST.value());
        }

        BicycleDTO dto = new BicycleDTO();
        dto.setName(name);
        dto.setCity(city);
        dto.setPrice(price);
        dto.setAvailableFrom(availableFrom);
        dto.setDescription(description);

        String email = userDetails.getUsername();
        Bicycle saved = bicycleService.saveBicycle(dto, email, imageFile);
        return ResponseEntity.ok(bicycleService.toResponseDto(saved));
    }

    /**
     * Updates an existing bicycle.
     *
     * @param userDetails   The details of the authenticated user.
     * @param id            The ID of the bicycle to update.
     * @param name          The new name of the bicycle.
     * @param city          The new city where the bicycle is located.
     * @param price         The new price per day for renting the bicycle.
     * @param availableFrom The new availableFrom the bicycle is available from.
     * @param description   A new description of the bicycle.
     * @param imageFile     An optional new image of the bicycle.
     * @return A response entity with the updated bicycle's data.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @PutMapping(value = "/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<BicycleResponseDTO> updateBicycleMultipartAtId(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestParam String name,
            @RequestParam String city,
            @RequestParam double price,
            @RequestParam String availableFrom,
            @RequestParam String description,
            @RequestParam(name = "imageUrl", required = false) MultipartFile imageFile
    ) throws ResponseException {
        try {
            LocalDate.parse(availableFrom);
        } catch (DateTimeParseException e) {
            throw new ResponseException("Bad Date format, use: YYYY-MM-DD", HttpStatus.BAD_REQUEST.value());
        }

        BicycleDTO dto = new BicycleDTO();
        dto.setName(name);
        dto.setCity(city);
        dto.setPrice(price);
        dto.setAvailableFrom(availableFrom);
        dto.setDescription(description);

        String email = userDetails.getUsername();
        Bicycle updatedBicycle;
        if (userDetails.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN"))) {
            updatedBicycle = bicycleService.updateBicycleAsAdmin(id, dto, email, imageFile);
        } else {
            updatedBicycle = bicycleService.updateBicycle(id, dto, email, imageFile);
        }
        return ResponseEntity.ok(bicycleService.toResponseDto(updatedBicycle));
    }

    /**
     * Updates a bicycle as an admin.
     *
     * @param id  The ID of the bicycle to update.
     * @param dto The request body with the updated bicycle details.
     * @return A response entity with the updated bicycle.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping(value = "/admin/{id}", consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Bicycle> updateBicycleAsAdminJson(
            @PathVariable Long id,
            @RequestBody BicycleDTO dto
    ) {
        return ResponseEntity.ok(bicycleService.updateBicycle(id, dto));
    }

    /**
     * Retrieves the bicycles of the current user.
     *
     * @param userDetails The details of the authenticated user.
     * @return A response entity with a list of the user's bicycles.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @GetMapping("/my")
    public ResponseEntity<List<BicycleResponseDTO>> getUserBicycles(@AuthenticationPrincipal UserDetails userDetails) {
        String email = userDetails.getUsername();
        List<Bicycle> bicycles = bicycleService.getUserBicycles(email);
        return ResponseEntity.ok(bicycleService.toResponseDtoList(bicycles));
    }

    /**
     * Retrieves all bicycles.
     *
     * @return A response entity with a list of all bicycles.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @GetMapping
    public ResponseEntity<List<BicycleResponseDTO>> getAllBicycles() {
        List<Bicycle> bicycles = bicycleService.getAllBicycles();
        return ResponseEntity.ok(bicycleService.toResponseDtoList(bicycles));
    }

    /**
     * Retrieves a bicycle by its ID.
     *
     * @param id The ID of the bicycle to retrieve.
     * @return A response entity with the bicycle's data.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @GetMapping("/{id}")
    public ResponseEntity<BicycleResponseDTO> getBicycleById(@PathVariable Long id) {
        return ResponseEntity.ok(bicycleService.getBicycleById(id));
    }

    /**
     * Deletes a bicycle.
     *
     * @param id The ID of the bicycle to delete.
     * @return A response entity indicating success.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBicycle(@PathVariable Long id) {
        bicycleService.deleteBicycle(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Previews an order for a bicycle.
     *
     * @param request The request body containing the order details.
     * @return A response entity with the order preview.
     */
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    @PostMapping("/order/preview")
    public ResponseEntity<OrderResponseDTO> previewOrder(@RequestBody OrderRequestDTO request) {
        OrderResponseDTO response = bicycleService.calculateOrderTotal(
                request.getBicycleId(),
                request.getDateFrom(),
                request.getDateTo()
        );
        return ResponseEntity.ok(response);
    }
}
