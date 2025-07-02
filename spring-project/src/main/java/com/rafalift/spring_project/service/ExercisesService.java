package com.rafalift.spring_project.service;

import com.rafalift.spring_project.model.Exercises;
import com.rafalift.spring_project.model.UserWorkouts;
import com.rafalift.spring_project.repository.ExercisesRepository;
import com.rafalift.spring_project.repository.UserWorkoutRepository;
import com.rafalift.spring_project.repository.WorkoutCategoriesRepository;
import com.rafalift.spring_project.security.UsersUtils;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@Transactional
public class ExercisesService {
    @Autowired
    private ExercisesRepository exercisesRepository;

    @Autowired
    private UserWorkoutRepository userWorkoutRepository;

    @Autowired
    private UsersUtils usersUtils;

    @Autowired
    private WorkoutCategoriesRepository workoutCategoriesRepository;

    public List<Exercises> getAllExercisesForLoggedUser(String workoutName) {
        Integer userId = usersUtils.getCurrentUserId();
        UserWorkouts userWorkout = userWorkoutRepository
                .findByUserIdAndWorkoutCategoryNome(userId.longValue(), workoutName)
                .orElseThrow(() -> new RuntimeException("User workout not found"));
        return exercisesRepository.findByWorkoutId(userWorkout.getId());
    }

    public Exercises addExerciseForWorkout(String workoutName, Exercises exercise) {
        Integer userId = usersUtils.getCurrentUserId();

        UserWorkouts userWorkout = userWorkoutRepository
                .findByUserIdAndWorkoutCategoryNome(userId.longValue(), workoutName)
                .orElseThrow(() -> new RuntimeException("User workout not found for workout: " + workoutName));

        if (userWorkout == null) {
            throw new RuntimeException("User workout not found for workout: " + workoutName);
        }

        exercise.setWorkout(userWorkout);

        return exercisesRepository.save(exercise);
    }



    public Exercises updateExercise(String workoutName, Integer exerciseId, Exercises updatedExercise) {
        Integer userId = usersUtils.getCurrentUserId();
        UserWorkouts userWorkout = userWorkoutRepository
                .findByUserIdAndWorkoutCategoryNome(userId.longValue(), workoutName)
                .orElseThrow(() -> new RuntimeException("User workout not found"));

        Exercises existingExercise = exercisesRepository.findById(exerciseId)
                .orElseThrow(() -> new RuntimeException("Exercise not found"));

        if (!existingExercise.getWorkout().getId().equals(userWorkout.getId())) {
            throw new RuntimeException("You cannot edit this exercise");
        }

        existingExercise.setGrupo_muscular(updatedExercise.getGrupo_muscular());
        existingExercise.setNome(updatedExercise.getNome());
        existingExercise.setSeries(updatedExercise.getSeries());
        existingExercise.setRepeticoes(updatedExercise.getRepeticoes());
        existingExercise.setPeso(updatedExercise.getPeso());
        existingExercise.setTempo(updatedExercise.getTempo());
        existingExercise.setAnotacao(updatedExercise.getAnotacao());

        return exercisesRepository.save(existingExercise);
    }

    public void deleteExercise(String workoutName, Integer exerciseId) {
        Integer userId = usersUtils.getCurrentUserId();
        UserWorkouts userWorkout = userWorkoutRepository
                .findByUserIdAndWorkoutCategoryNome(userId.longValue(), workoutName)
                .orElseThrow(() -> new RuntimeException("User workout not found"));

        Exercises exercise = exercisesRepository.findById(exerciseId)
                .orElseThrow(() -> new RuntimeException("Exercise not found"));

        if (!exercise.getWorkout().getId().equals(userWorkout.getId())) {
            throw new RuntimeException("You cannot delete this exercise");
        }

        exercisesRepository.delete(exercise);
    }
}