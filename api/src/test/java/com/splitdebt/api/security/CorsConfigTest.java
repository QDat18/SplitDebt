package com.splitdebt.api.security;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.filter.CorsFilter;

import static org.junit.jupiter.api.Assertions.*;

class CorsConfigTest {
    private MockHttpServletResponse preflight(String origin, String path) throws Exception {
        var config = new SecurityConfig(null, null, null);
        ReflectionTestUtils.setField(config, "allowedOrigins", "http://localhost:3000,http://127.0.0.1:3000");
        var request = new MockHttpServletRequest("OPTIONS", path);
        request.addHeader("Origin", origin);
        request.addHeader("Access-Control-Request-Method", "POST");
        request.addHeader("Access-Control-Request-Headers", "content-type,authorization");
        var response = new MockHttpServletResponse();
        new CorsFilter(config.corsConfigurationSource()).doFilter(request, response, new MockFilterChain());
        return response;
    }
    @Test void loginFromLocalhost() throws Exception {
        var response = preflight("http://localhost:3000", "/api/auth/login");
        assertEquals(200, response.getStatus());
        assertEquals("http://localhost:3000", response.getHeader("Access-Control-Allow-Origin"));
    }
    @Test void ocrFromLoopback() throws Exception {
        var response = preflight("http://127.0.0.1:3000", "/api/v1/receipts/advanced");
        assertEquals(200, response.getStatus());
        assertEquals("http://127.0.0.1:3000", response.getHeader("Access-Control-Allow-Origin"));
    }
    @Test void rejectOtherOrigins() throws Exception {
        var response = preflight("https://untrusted.example", "/api/auth/login");
        assertEquals(403, response.getStatus());
        assertNull(response.getHeader("Access-Control-Allow-Origin"));
    }
    @Test void rejectUnexpectedPort() throws Exception {
        assertEquals(403, preflight("http://localhost:3001", "/api/auth/login").getStatus());
    }
}
