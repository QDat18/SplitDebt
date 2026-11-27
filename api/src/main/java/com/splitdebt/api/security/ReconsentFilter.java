/**
 * Trách nhiệm file: Chặn các API nghiệp vụ với mã 428 nếu người dùng chưa đồng ý phiên bản điều khoản hiện hành.
 */

package com.splitdebt.api.security;

import com.splitdebt.api.entity.User;
import com.splitdebt.api.repository.UserRepository;
import com.splitdebt.api.service.ConsentService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class ReconsentFilter extends OncePerRequestFilter {

    private static final String BODY_428 =
            "{\"status\":428,\"code\":\"RECONSENT_REQUIRED\",\"message\":\"Bạn cần đồng ý điều khoản mới để tiếp tục.\"}";

    private final ConsentService consentService;
    private final UserRepository userRepository;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        if (!path.startsWith("/api/") || isExempt(method, path)) {
            filterChain.doFilter(request, response);
            return;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            filterChain.doFilter(request, response);
            return;
        }

        Optional<User> userOpt = userRepository.findByEmail(auth.getName());
        if (userOpt.isPresent() && consentService.reconsentRequired(userOpt.get().getId())) {
            response.setStatus(428);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(BODY_428);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean isExempt(String method, String path) {
        if (path.startsWith("/api/auth/")) {
            return true;
        }
        if ("GET".equalsIgnoreCase(method) && "/api/users/me".equals(path)) {
            return true;
        }
        return "/api/users/me/consents".equals(path)
                || "/api/users/me/data-export".equals(path)
                || "/api/users/me/deletion".equals(path)
                || "/api/health".equals(path);
    }
}

