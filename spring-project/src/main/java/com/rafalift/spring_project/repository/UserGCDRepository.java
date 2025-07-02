package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.UserGCD;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserGCDRepository extends JpaRepository<UserGCD, Integer> {
    Optional<UserGCD> findByUserId(Integer userId);
}
