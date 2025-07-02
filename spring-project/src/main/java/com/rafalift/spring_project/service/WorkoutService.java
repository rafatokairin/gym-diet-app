package com.rafalift.spring_project.service;

import com.rafalift.spring_project.dto.UserWorkoutDTO;
import com.rafalift.spring_project.dto.WorkoutDaysRequest;
import com.rafalift.spring_project.model.*;
import com.rafalift.spring_project.repository.DaysCategoriesRepository;
import com.rafalift.spring_project.repository.ExercisesRepository;
import com.rafalift.spring_project.repository.UserWorkoutRepository;
import com.rafalift.spring_project.repository.WorkoutDayRepository;
import com.rafalift.spring_project.security.UsersUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class WorkoutService {

    @Autowired
    private UserWorkoutRepository userWorkoutRepository;

    @Autowired
    private WorkoutDayRepository workoutDayRepository;

    @Autowired
    private DaysCategoriesRepository daysCategoryRepository;

    @Autowired
    private UsersUtils usersUtils;

    @Autowired
    private ExercisesRepository exercisesRepository;

    public List<UserWorkoutDTO> getUserWorkouts() {
        Integer userId = usersUtils.getCurrentUserId();

        List<UserWorkouts> workouts = userWorkoutRepository.findByUserId(userId.longValue());

        List<UserWorkoutDTO> workoutDTOs = new ArrayList<>();

        for (UserWorkouts workout : workouts) {
            List<WorkoutDays> days = workoutDayRepository.findByUserWorkout(workout);
            List<String> dayNames = days.stream()
                    .map(wd -> wd.getDay().getNome())
                    .toList();
            workoutDTOs.add(new UserWorkoutDTO(workout.getWorkoutCategory().getNome(), dayNames));
        }

        return workoutDTOs;
    }

    public void updateWorkoutDays(WorkoutDaysRequest request) {
        Integer userId = usersUtils.getCurrentUserId();

        UserWorkouts userWorkout = userWorkoutRepository.findByUserIdAndWorkoutCategoryNome(userId.longValue(), request.setName())
                .orElseThrow(() -> new RuntimeException("Treino não encontrado"));

        // Apaga dias antigos
        List<WorkoutDays> existingDays = workoutDayRepository.findByUserWorkout(userWorkout);
        workoutDayRepository.deleteAll(existingDays);

        // Adiciona novos dias
        for (String dayName : request.days()) {
            DaysCategories day = daysCategoryRepository.findByNomeIgnoreCase(dayName.toLowerCase())
                    .orElseThrow(() -> new RuntimeException("Dia inválido: " + dayName));

            WorkoutDays workoutDay = new WorkoutDays();
            workoutDay.setUserWorkout(userWorkout);
            workoutDay.setDay(day);
            workoutDay.setId(new WorkoutDayId(userWorkout.getId(), day.getId()));
            workoutDayRepository.save(workoutDay);
        }
    }

    public List<Exercises> getWorkoutByDay(String dayName) {
        Integer userId = usersUtils.getCurrentUserId();
        Integer dayId = daysCategoryRepository.findByNomeIgnoreCase(dayName)
                .orElseThrow(() -> new RuntimeException("Dia não encontrado"))
                .getId();

        List<UserWorkouts> userWorkouts = userWorkoutRepository.findByUserId(userId.longValue());

        for (UserWorkouts workout : userWorkouts) {
            List<WorkoutDays> days = workoutDayRepository.findByUserWorkout(workout);
            for (WorkoutDays wd : days) {
                if (wd.getDay().getId().equals(dayId)) {
                    return exercisesRepository.findByWorkoutId(workout.getId());
                }
            }
        }

        return List.of(); // Nenhum treino para hoje
    }
}
