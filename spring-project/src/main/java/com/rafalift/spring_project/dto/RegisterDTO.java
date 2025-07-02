package com.rafalift.spring_project.dto;

import com.rafalift.spring_project.model.UserRole;

public record RegisterDTO(String nome, String email, String senha, UserRole role) {}
