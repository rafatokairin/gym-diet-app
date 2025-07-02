package com.rafalift.spring_project.model;

import jakarta.persistence.*;

@Entity
@Table(name = "workout_days")
public class WorkoutDays {
    @EmbeddedId
    private WorkoutDayId id = new WorkoutDayId();

    @ManyToOne
    @MapsId("userWorkoutsId")
    @JoinColumn(name = "user_workouts_id")
    private UserWorkouts userWorkout;

    @ManyToOne
    @MapsId("dayId")
    @JoinColumn(name = "day_id")
    private DaysCategories day;

    public WorkoutDayId getId() {
        return id;
    }

    public void setId(WorkoutDayId id) {
        this.id = id;
    }

    public UserWorkouts getUserWorkout() {
        return userWorkout;
    }

    public void setUserWorkout(UserWorkouts userWorkout) {
        this.userWorkout = userWorkout;
    }

    public DaysCategories getDay() {
        return day;
    }

    public void setDay(DaysCategories day) {
        this.day = day;
    }
}
