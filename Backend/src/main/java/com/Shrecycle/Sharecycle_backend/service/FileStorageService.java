package com.Shrecycle.Sharecycle_backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.time.Instant;

/**
 * Service for handling file storage operations.
 */
@Service
public class FileStorageService {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    /**
     * Saves a user's profile image.
     * @param userId The ID of the user.
     * @param file The image file to save.
     * @return The URL of the saved image.
     * @throws IOException if an I/O error occurs.
     */
    public String saveUserImage(Long userId, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) return null;

        String ct = file.getContentType();
        if (ct == null || !ct.toLowerCase().startsWith("image/")) {
            throw new IOException("Only image files are allowed");
        }

        String original = StringUtils.cleanPath(file.getOriginalFilename() == null ? "" : file.getOriginalFilename());
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot != -1 && dot < original.length() - 1) ext = original.substring(dot).toLowerCase();

        String filename = "user-" + userId + "-" + Instant.now().toEpochMilli() + ext;

        Path dir = Paths.get(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(dir);

        Path target = dir.resolve(filename);
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        // URL that matches WebConfig
        return "/uploads/" + filename;
    }

    /**
     * Saves an admin's profile image.
     * @param adminId The ID of the admin.
     * @param file The image file to save.
     * @return The URL of the saved image.
     * @throws IOException if an I/O error occurs.
     */
    public String saveAdminImage(Long adminId, MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) return null;

        String ct = file.getContentType();
        if (ct == null || !ct.toLowerCase().startsWith("image/")) {
            throw new IOException("Only image files are allowed");
        }

        String original = StringUtils.cleanPath(file.getOriginalFilename() == null ? "" : file.getOriginalFilename());
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot != -1 && dot < original.length() - 1) ext = original.substring(dot).toLowerCase();

        String filename = "admin-" + adminId + "-" + Instant.now().toEpochMilli() + ext;

        Path dir = Paths.get(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(dir);

        Path target = dir.resolve(filename);
        Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);

        // URL that matches WebConfig
        return "/uploads/" + filename;
    }
}
