// TokenService.java
package com.rafalift.spring_project.security;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTCreationException;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.rafalift.spring_project.model.Users;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Service
public class TokenService {
    @Value("${api.security.token.secret}")
    private String secret;

    @Value("${auth.jwt.token.expiration}")
    private Integer timeExpToken;               // em minutos

    @Value("${auth.jwt.refresh-token.expiration}")
    private Integer timeExpRefreshToken;        // em minutos

    private Algorithm getAlgorithm() {
        return Algorithm.HMAC256(secret);
    }

    private Instant genExpirationDate(Integer expirationMinutes) {
        return LocalDateTime.now()
                .plusHours(expirationMinutes)
                .toInstant(ZoneOffset.of("-03:00"));
    }

    public String generateAccessToken(Users user) {
        try {
            return JWT.create()
                    .withIssuer("auth-api")
                    .withSubject(user.getEmail())
                    .withClaim("type", "access")
                    .withExpiresAt(genExpirationDate(timeExpToken))
                    .sign(getAlgorithm());
        } catch (JWTCreationException e) {
            throw new RuntimeException("Could not generate access token", e);
        }
    }

    public String generateRefreshToken(Users user) {
        try {
            return JWT.create()
                    .withIssuer("auth-api")
                    .withSubject(user.getEmail())
                    .withClaim("type", "refresh")
                    .withExpiresAt(genExpirationDate(timeExpRefreshToken))
                    .sign(getAlgorithm());
        } catch (JWTCreationException e) {
            throw new RuntimeException("Could not generate refresh token", e);
        }
    }

    /**
     * Verifica assinatura, issuer e expiração. 
     * Retorna o JWT decodificado para permitir checar claims. 
     * Lança JWTVerificationException em caso de falha.
     */
    public DecodedJWT decodeToken(String token) throws JWTVerificationException {
        return JWT.require(getAlgorithm())
                .withIssuer("auth-api")
                .build()
                .verify(token);
    }
}
