package com.rafalift.spring_project.dto;

import java.util.List;

public record UserWorkoutDTO(String setName, List<String> days) {}
