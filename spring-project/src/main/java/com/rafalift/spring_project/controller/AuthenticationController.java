// AuthenticationController.java
package com.rafalift.spring_project.controller;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.rafalift.spring_project.dto.AuthenticationDTO;
import com.rafalift.spring_project.dto.RegisterDTO;
import com.rafalift.spring_project.model.UserRole;
import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.repository.UsersRepository;
import com.rafalift.spring_project.security.TokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("auth")
public class AuthenticationController {
    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UsersRepository repository;

    @Autowired
    private TokenService tokenService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody @Validated AuthenticationDTO data) {
        var authToken = new UsernamePasswordAuthenticationToken(data.login(), data.password());
        var auth = authenticationManager.authenticate(authToken);
        var user = (Users) auth.getPrincipal();

        String accessToken  = tokenService.generateAccessToken(user);
        String refreshToken = tokenService.generateRefreshToken(user);

        return ResponseEntity.ok(Map.of(
                "access_token",  accessToken,
                "refresh_token", refreshToken
        ));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody @Validated RegisterDTO data) {
        if (repository.findByEmail(data.email()) != null)
            return ResponseEntity.badRequest().build();

        String encrypted = new BCryptPasswordEncoder().encode(data.senha());
        Users newUser = new Users(data.nome(), data.email(), encrypted, UserRole.USER);
        repository.save(newUser);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(HttpServletResponse response) {
        ResponseCookie cookie = ResponseCookie.from("jwt", "")
                .httpOnly(true)
                .secure(false)
                .path("/")
                .sameSite("Strict")
                .maxAge(0)
                .build();
        response.setHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/check")
    public ResponseEntity<?> checkAuth() {
        return ResponseEntity.ok().build();
    }

    @GetMapping("/validate")
    public ResponseEntity<?> validateToken(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String email = authentication.getName();
        if (!repository.existsByEmail(email)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok().build();
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(HttpServletRequest request,
                                          @RequestBody(required = false) Map<String, String> body) {
        // 1) Extrai do Authorization header, se existir
        String refreshToken = null;
        String authHeader = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            refreshToken = authHeader.substring(7);
        } else if (body != null) {
            // 2) Se não veio por header, pega do body JSON
            refreshToken = body.get("refresh_token");
        }

        if (refreshToken == null || refreshToken.isBlank()) {
            return ResponseEntity
                    .badRequest()
                    .body("Refresh token é obrigatório");
        }

        DecodedJWT jwt;
        try {
            // valida assinatura, issuer e expiração
            jwt = tokenService.decodeToken(refreshToken);
        } catch (Exception ex) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Refresh token inválido ou expirado");
        }

        // 3) Confirma que é mesmo um refresh token
        String type = jwt.getClaim("type").asString();
        if (!"refresh".equals(type)) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Token enviado não é um refresh token");
        }

        // 4) Busca usuário e gera NOVO ACCESS TOKEN APENAS
        String email = jwt.getSubject();
        Users user = (Users) repository.findByEmail(email);
        if (user == null) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Usuário não encontrado");
        }

        String newAccessToken = tokenService.generateAccessToken(user);
        return ResponseEntity.ok(Map.of(
                "access_token", newAccessToken
                // Não gerar novo refresh token aqui
        ));
    }
}
