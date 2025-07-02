package com.rafalift.spring_project.repository;

import com.rafalift.spring_project.model.UserWorkouts;
import com.rafalift.spring_project.model.WorkoutDayId;
import com.rafalift.spring_project.model.WorkoutDays;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkoutDayRepository extends JpaRepository<WorkoutDays, WorkoutDayId> {
    List<WorkoutDays> findByUserWorkout(UserWorkouts userWorkout);
}