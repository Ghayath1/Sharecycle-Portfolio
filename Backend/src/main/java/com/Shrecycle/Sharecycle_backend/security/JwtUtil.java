package com.Shrecycle.Sharecycle_backend.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Utility class for handling JWTs.
 * Provides methods for generating, validating, and extracting claims from JWTs.
 */
@Component
public class JwtUtil {

    private final String jwtSecret = "yourSecretKeyForJWTSigningMustBeLongEnoughToBeSecure123!"; // Must be at least 256 bits
    private final long jwtExpirationMs = 86400000; // 1 day

    /**
     * Returns the signing key for the JWT.
     * @return The signing key.
     */
    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    /**
     * Generates a JWT for a given user.
     * @param userDetails The user to generate the token for.
     * @return The generated JWT.
     */
    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();

        // Add roles/authorities to the claims
        List<String> authorities = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.toList());
        claims.put("authorities", authorities);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(userDetails.getUsername()) // usually the email
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + jwtExpirationMs))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * Extracts the username from a JWT.
     * @param token The JWT to extract the username from.
     * @return The username.
     */
    public String extractUsername(String token) {
        return extractAllClaims(token).getSubject();
    }

    /**
     * Validates a JWT.
     * @param token The JWT to validate.
     * @param userDetails The user details to validate against.
     * @return true if the token is valid, false otherwise.
     */
    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    /**
     * Validates a JWT.
     * @param token The JWT to validate.
     * @param username The username to validate against.
     * @return true if the token is valid, false otherwise.
     */
    public boolean validateToken(String token, String username) {
        return (username.equals(extractUsername(token)) && !isTokenExpired(token));
    }

    /**
     * Checks if a JWT is expired.
     * @param token The JWT to check.
     * @return true if the token is expired, false otherwise.
     */
    private boolean isTokenExpired(String token) {
        return extractAllClaims(token).getExpiration().before(new Date());
    }

    /**
     * Extracts all claims from a JWT.
     * @param token The JWT to extract the claims from.
     * @return The claims.
     */
    public Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }
}
