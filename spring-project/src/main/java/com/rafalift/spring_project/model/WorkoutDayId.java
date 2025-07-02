package com.rafalift.spring_project.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;

@Embeddable
public class WorkoutDayId implements Serializable {
    @Column(name = "user_workouts_id")
    private Integer userWorkoutsId;

    @Column(name = "day_id")
    private Integer dayId;

    public WorkoutDayId() {
    }

    public WorkoutDayId(Integer userWorkoutsId, Integer dayId) {
        userWorkoutsId = userWorkoutsId;
        dayId = dayId;
    }

    public Integer getUserWorkoutsId() {
        return userWorkoutsId;
    }

    public void setUserWorkoutsId(Integer userWorkoutsId) {
        this.userWorkoutsId = userWorkoutsId;
    }

    public Integer getDayId() {
        return dayId;
    }

    public void setDayId(Integer dayId) {
        this.dayId = dayId;
    }
}