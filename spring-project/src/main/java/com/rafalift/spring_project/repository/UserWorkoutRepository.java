package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.UserWorkouts;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserWorkoutRepository extends JpaRepository<UserWorkouts, Long> {
    List<UserWorkouts> findByUserId(Long userId);

    Optional<UserWorkouts> findByUserIdAndWorkoutCategoryNome(Long userId, String nome);
}