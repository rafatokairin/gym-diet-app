package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.DaysCategories;
import com.rafalift.spring_project.model.WorkoutCategories;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface WorkoutCategoriesRepository extends JpaRepository<WorkoutCategories, Integer> {
    Optional<DaysCategories> findByNomeIgnoreCase(String nome);
}
