package com.splitdebt.api.ledger;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Map;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class AuthFilter extends OncePerRequestFilter {
    public record User(long id, String email, String name) {}

    private final JwtService jwt;
    private final ObjectMapper mapper;

    public AuthFilter(JwtService jwt, ObjectMapper mapper) {
        this.jwt = jwt;
        this.mapper = mapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        return !path.startsWith("/api/")
                || path.equals("/api/health")
                || path.equals("/api/auth/login")
                || path.equals("/api/auth/register")
                || request.getMethod().equals("OPTIONS");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            error(response, 401, "Please sign in to continue.");
            return;
        }
        JwtService.Claims claims = jwt.verify(header.substring(7).trim());
        if (claims == null) {
            error(response, 401, "Your session expired. Please sign in again.");
            return;
        }
        request.setAttribute("user", new User(claims.userId(), claims.email(), claims.name()));
        chain.doFilter(request, response);
    }

    private void error(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        mapper.writeValue(response.getWriter(), Map.of("message", message));
    }
}
