package com.rafalift.spring_project.controller;

import com.rafalift.spring_project.model.UserGCD;
import com.rafalift.spring_project.service.UserGCDService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("UserGcd")
public class UserGCDController {
    @Autowired
    private UserGCDService userGCDService;

    @GetMapping
    public ResponseEntity<UserGCD> getUserGCD() {
        UserGCD userGCD = userGCDService.getUserGCD();
        return ResponseEntity.ok(userGCD);
    }

    @PostMapping
    public ResponseEntity<UserGCD> addUserGCD(@RequestBody UserGCD userGCD) {
        UserGCD savedUserGCD = userGCDService.addUserGCD(userGCD);
        return ResponseEntity.ok(savedUserGCD);
    }

    @PutMapping
    public ResponseEntity<UserGCD> updateUserGCD(@RequestBody UserGCD updateGCD) {
        UserGCD updatedUserGCD = userGCDService.updateUserGCD(updateGCD);
        return ResponseEntity.ok(updatedUserGCD);
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteUserGCD() {
        userGCDService.deleteUserGCD();
        return ResponseEntity.noContent().build();
    }
}
