package com.rafalift.spring_project.controller;

import com.rafalift.spring_project.model.Exercises;
import com.rafalift.spring_project.service.ExercisesService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/WorkoutSet")
public class ExercisesController {

    @Autowired
    private ExercisesService exercisesService;

    @GetMapping("/{workout}")
    public ResponseEntity<List<Exercises>> getExercisesByWorkout(@PathVariable String workout) {
        List<Exercises> exercises = exercisesService.getAllExercisesForLoggedUser(workout);
        return ResponseEntity.ok(exercises);
    }

    @PostMapping("/{workout}")
    public ResponseEntity<Exercises> addExercise(@PathVariable String workout, @RequestBody Exercises exercise) {
        Exercises createdExercise = exercisesService.addExerciseForWorkout(workout, exercise);
        return ResponseEntity.ok(createdExercise);
    }

    @PutMapping("/{workout}/{exerciseId}")
    public ResponseEntity<Exercises> updateExercise(
            @PathVariable String workout,
            @PathVariable Integer exerciseId,
            @RequestBody Exercises updatedExercise) {
        Exercises updated = exercisesService.updateExercise(workout, exerciseId, updatedExercise);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{workout}/{exerciseId}")
    public ResponseEntity<Void> deleteExercise(@PathVariable String workout, @PathVariable Integer exerciseId) {
        exercisesService.deleteExercise(workout, exerciseId);
        return ResponseEntity.noContent().build();
    }
}
