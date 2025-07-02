package com.rafalift.spring_project.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_workouts")
public class UserWorkouts {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private Users user;

    @ManyToOne
    @JoinColumn(name = "workout_id")
    private WorkoutCategories workoutCategory;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Users getUser() {
        return user;
    }

    public void setUser(Users user) {
        this.user = user;
    }

    public WorkoutCategories getWorkoutCategory() {
        return workoutCategory;
    }

    public void setWorkoutCategory(WorkoutCategories workoutCategory) {
        this.workoutCategory = workoutCategory;
    }
}
