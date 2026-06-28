package com.Shrecycle.Sharecycle_backend.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * A filter that handles JWT-based authentication.
 * This filter intercepts incoming requests, extracts the JWT from the Authorization header,
 * validates it, and sets the user's authentication in the security context.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    /**
     * Constructs a new JwtAuthenticationFilter.
     * @param jwtUtil The JWT utility to use for token operations.
     */
    public JwtAuthenticationFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    /**
     * Performs the filtering logic for JWT authentication.
     * @param request The HTTP request.
     * @param response The HTTP response.
     * @param filterChain The filter chain.
     * @throws ServletException if a servlet-specific error occurs.
     * @throws IOException if an I/O error occurs.
     */
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // Allow unauthenticated access to auth routes
        String path = request.getRequestURI();
        if (path.startsWith("/api/auth/")) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        String token = null;
        String username = null;

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7);

            try {
                username = jwtUtil.extractUsername(token);
            } catch (Exception e) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT token");
                return;
            }
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            // Validate the token and extract authorities from claims
            if (jwtUtil.validateToken(token, username)) {
                Claims claims = jwtUtil.extractAllClaims(token);

                @SuppressWarnings("unchecked")
                List<String> authoritiesList = claims.get("authorities", List.class);

                List<SimpleGrantedAuthority> authorities = authoritiesList.stream()
                        .map(SimpleGrantedAuthority::new)
                        .collect(Collectors.toList());

                UserDetails userDetails = new org.springframework.security.core.userdetails.User(
                        username,
                        "", // password not needed
                        authorities
                );

                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(userDetails, null, authorities);

                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        filterChain.doFilter(request, response);
    }
}
