package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.DaysCategories;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface DaysCategoriesRepository extends JpaRepository<DaysCategories, Integer> {
    Optional<DaysCategories> findByNomeIgnoreCase(String nome);
}
