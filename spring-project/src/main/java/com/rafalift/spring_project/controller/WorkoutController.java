package com.rafalift.spring_project.controller;

import com.rafalift.spring_project.model.Exercises;
import com.rafalift.spring_project.dto.UserWorkoutDTO;
import com.rafalift.spring_project.dto.WorkoutDaysRequest;
import com.rafalift.spring_project.service.WorkoutService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/workouts")
public class WorkoutController {

    @Autowired
    private WorkoutService workoutService;

    @GetMapping
    public ResponseEntity<List<UserWorkoutDTO>> getUserWorkouts() {
        List<UserWorkoutDTO> workouts = workoutService.getUserWorkouts();
        return ResponseEntity.ok(workouts);
    }

    @PostMapping("/set-days")
    public ResponseEntity<Void> updateWorkoutDays(@RequestBody WorkoutDaysRequest request) {
        workoutService.updateWorkoutDays(request);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{day}")
    public ResponseEntity<List<Exercises>> getWorkoutByDay(@PathVariable String day) {
        return ResponseEntity.ok(workoutService.getWorkoutByDay(day));
    }
}
