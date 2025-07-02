package com.rafalift.spring_project.service;

import com.rafalift.spring_project.model.Foods;
import com.rafalift.spring_project.model.UserDiets;
import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.repository.DaysCategoriesRepository;
import com.rafalift.spring_project.repository.FoodsRepository;
import com.rafalift.spring_project.repository.UserDietsRepository;
import com.rafalift.spring_project.repository.UsersRepository;
import com.rafalift.spring_project.security.UsersUtils;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@Transactional
public class FoodsService {

    @Autowired
    private FoodsRepository foodsRepository;
    @Autowired
    private UserDietsRepository userDietsRepository;
    @Autowired
    private DaysCategoriesRepository daysCategoriesRepository;
    @Autowired
    private UsersUtils usersUtils;

    public List<Foods> getAllFoodsForLoggedUser(String dayName) {
        Integer userId = usersUtils.getCurrentUserId();

        UserDiets userDiet = userDietsRepository
                .findByUserIdAndDay_Nome(userId.longValue(), dayName)
                .orElseThrow(() -> new RuntimeException("User diet not found"));
        return foodsRepository.findByDiet(userDiet);
    }

    public Foods addFoodForDay(String dayName, Foods food) {
        Integer userId = usersUtils.getCurrentUserId();

        UserDiets userDiet = userDietsRepository.findByUserIdAndDay_Nome(userId.longValue(), dayName)
                .orElseThrow(() -> new RuntimeException("User diet not found"));

        if (userDiet == null) {
            throw new RuntimeException("User workout not found for workout: " + dayName);
        }

        food.setDiet(userDiet);
        return foodsRepository.save(food);
    }

    public Foods updateFood(String dayName, Integer foodId, Foods updatedFood) {
        Integer userId = usersUtils.getCurrentUserId();

        UserDiets userDiet = userDietsRepository.findByUserIdAndDay_Nome(userId.longValue(), dayName)
                .orElseThrow(() -> new RuntimeException("User diet not found"));

        Foods existingFood = foodsRepository.findById(foodId)
                .orElseThrow(() -> new RuntimeException("Food not found"));

        if (!existingFood.getDiet().getId().equals(userDiet.getId())) {
            throw new RuntimeException("You cannot edit this food");
        }

        existingFood.setTipo_alimento(updatedFood.getTipo_alimento());
        existingFood.setAlimento(updatedFood.getAlimento());
        existingFood.setPeso(updatedFood.getPeso());
        existingFood.setCalorias(updatedFood.getCalorias());
        existingFood.setCarboidratos(updatedFood.getCarboidratos());
        existingFood.setProteinas(updatedFood.getProteinas());
        existingFood.setFibras(updatedFood.getFibras());
        existingFood.setGorduras(updatedFood.getGorduras());
        existingFood.setAnotacao(updatedFood.getAnotacao());
        existingFood.setHorario(updatedFood.getHorario());

        return foodsRepository.save(existingFood);
    }

    public void deleteFood(String dayName, Integer foodId) {
        Integer userId = usersUtils.getCurrentUserId();

        UserDiets userDiet = userDietsRepository.findByUserIdAndDay_Nome(userId.longValue(), dayName)
                .orElseThrow(() -> new RuntimeException("User diet not found"));

        Foods food = foodsRepository.findById(foodId)
                .orElseThrow(() -> new RuntimeException("Food not found"));

        if (!food.getDiet().getId().equals(userDiet.getId())) {
            throw new RuntimeException("You cannot delete this food");
        }

        foodsRepository.delete(food);
    }
}