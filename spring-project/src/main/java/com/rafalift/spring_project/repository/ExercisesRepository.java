package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.Exercises;
import com.rafalift.spring_project.model.UserWorkouts;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ExercisesRepository extends JpaRepository<Exercises, Integer> {
    List<Exercises> findByWorkoutId(Integer userWorkout);
}
