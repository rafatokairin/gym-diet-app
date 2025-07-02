package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.UserDiets;
import com.rafalift.spring_project.model.UserWorkouts;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserDietsRepository extends JpaRepository<UserDiets, Integer> {
    Optional<UserDiets> findByUserId(Integer userId);
    Optional<UserDiets> findByUserIdAndDay_Nome(Long userId, String nome);
}