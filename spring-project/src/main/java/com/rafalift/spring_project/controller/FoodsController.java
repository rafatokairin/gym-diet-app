package com.rafalift.spring_project.controller;

import com.rafalift.spring_project.model.Foods;
import com.rafalift.spring_project.service.FoodsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/DietDay")
public class FoodsController {

    @Autowired
    private FoodsService foodsService;

    @GetMapping("/{day}")
    public ResponseEntity<List<Foods>> getFoodsByDay(@PathVariable String day) {
        List<Foods> foods = foodsService.getAllFoodsForLoggedUser(day);
        return ResponseEntity.ok(foods);
    }

    @PostMapping("/{day}")
    public ResponseEntity<Foods> addFood(@PathVariable String day, @RequestBody Foods food) {
        Foods createdFood = foodsService.addFoodForDay(day, food);
        return ResponseEntity.ok(createdFood); // HTTP 201 Created
    }

    @PutMapping("/{day}/{foodId}")
    public ResponseEntity<Foods> updateFood(@PathVariable String day, @PathVariable Integer foodId, @RequestBody Foods food) {
        Foods updatedFood = foodsService.updateFood(day, foodId, food);
        return ResponseEntity.ok(updatedFood);
    }

    @DeleteMapping("/{day}/{foodId}")
    public ResponseEntity<Void> deleteFood(@PathVariable String day, @PathVariable Integer foodId) {
        foodsService.deleteFood(day, foodId);
        return ResponseEntity.noContent().build(); // HTTP 204 No Content
    }
}