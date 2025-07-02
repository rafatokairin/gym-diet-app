package com.rafalift.spring_project.service;

import com.rafalift.spring_project.model.UserGCD;
import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.repository.UserGCDRepository;
import com.rafalift.spring_project.security.UsersUtils;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class UserGCDService {

    @Autowired
    private UsersUtils usersUtils;

    @Autowired
    private UserGCDRepository userGCDRepository;

    // Versão modificada que retorna Optional
    public Optional<UserGCD> findUserGCD() {
        Integer userId = usersUtils.getCurrentUserId();
        return userGCDRepository.findByUserId(userId);
    }

    // Versão original modificada para retornar null em vez de lançar exceção
    public UserGCD getUserGCD() {
        return findUserGCD().orElse(null);
    }

    // Versão para o frontend que retorna Map ou vazio
    public Map<String, Integer> getUserGCDData() {
        return findUserGCD()
                .map(gcd -> Map.of(
                        "carboidratos", gcd.getCarboidratos_gcd(),
                        "proteinas", gcd.getProteinas_gcd(),
                        "fibras", gcd.getFibras_gcd(),
                        "gorduras", gcd.getGorduras_gcd(),
                        "calorias", gcd.getGcd()
                ))
                .orElse(Collections.emptyMap());
    }

    public UserGCD addUserGCD(UserGCD userGCD) {
        Integer userId = usersUtils.getCurrentUserId();
        Users user = new Users();
        user.setId(userId);
        userGCD.setUser(user);
        return userGCDRepository.save(userGCD);
    }

    public UserGCD updateUserGCD(UserGCD updateGCD) {
        Integer userId = usersUtils.getCurrentUserId();

        UserGCD existingUserGCD = userGCDRepository.findByUserId(userId)
                .orElseGet(() -> {
                    UserGCD newGCD = new UserGCD();
                    Users user = new Users();
                    user.setId(userId);
                    newGCD.setUser(user);
                    return newGCD;
                });

        existingUserGCD.setCarboidratos_gcd(updateGCD.getCarboidratos_gcd());
        existingUserGCD.setProteinas_gcd(updateGCD.getProteinas_gcd());
        existingUserGCD.setFibras_gcd(updateGCD.getFibras_gcd());
        existingUserGCD.setGorduras_gcd(updateGCD.getGorduras_gcd());
        existingUserGCD.setGcd(updateGCD.getGcd());

        return userGCDRepository.save(existingUserGCD);
    }

    public void deleteUserGCD() {
        Integer userId = usersUtils.getCurrentUserId();
        UserGCD userGCD = userGCDRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("UserGCD not found"));
        userGCDRepository.delete(userGCD);
    }
}