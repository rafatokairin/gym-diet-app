package com.rafalift.spring_project.controller;

import com.rafalift.spring_project.dto.NameUpdateDTO;
import com.rafalift.spring_project.dto.PasswordUpdateDTO;
import com.rafalift.spring_project.model.Users;
import com.rafalift.spring_project.security.UsersUtils;
import com.rafalift.spring_project.service.UsersService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/account")
public class UsersController {
    private final UsersService usersService;
    private final UsersUtils usersUtils;

    public UsersController(UsersService usersService, UsersUtils usersUtils) {
        this.usersService = usersService;
        this.usersUtils = usersUtils;
    }

    @GetMapping
    public ResponseEntity<?> getCurrentUser() {
        return ResponseEntity.ok(usersUtils.getCurrentUser());
    }

    @PutMapping("/name")
    public ResponseEntity<?> updateName(@RequestBody NameUpdateDTO nameUpdate) {
        Integer userId = usersUtils.getCurrentUserId();
        Users user = usersService.findById(userId);
        user.setNome(nameUpdate.newName());
        return ResponseEntity.ok(usersService.updateById(userId, user));
    }

    @PutMapping("/password")
    public ResponseEntity<?> updatePassword(@RequestBody PasswordUpdateDTO passwordUpdate) {
        Integer userId = usersUtils.getCurrentUserId();
        Users user = usersService.findById(userId);

        // Verificar se a senha atual está correta
        if (!BCrypt.checkpw(passwordUpdate.currentPassword(), user.getSenha())) {
            return ResponseEntity.badRequest().body("Senha atual incorreta");
        }

        // Atualizar a senha
        String encryptedPassword = new BCryptPasswordEncoder().encode(passwordUpdate.newPassword());
        user.setSenha(encryptedPassword);
        return ResponseEntity.ok(usersService.updateById(userId, user));
    }

    @DeleteMapping
    public ResponseEntity<?> deleteAccount(@RequestBody String currentPassword) {
        Integer userId = usersUtils.getCurrentUserId();
        Users user = usersService.findById(userId);

        // Verificar se a senha atual está correta
        if (!BCrypt.checkpw(currentPassword, user.getSenha())) {
            return ResponseEntity.badRequest().body("Senha incorreta");
        }

        usersService.deleteById(userId);
        return ResponseEntity.ok("Conta excluída com sucesso");
    }
}