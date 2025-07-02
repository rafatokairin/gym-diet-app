package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.Foods;
import com.rafalift.spring_project.model.UserDiets;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FoodsRepository extends JpaRepository<Foods, Integer> {
    List<Foods> findByDiet(UserDiets diet);
}