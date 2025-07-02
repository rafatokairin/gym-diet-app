package com.rafalift.spring_project.dto;

import java.util.List;

public record WorkoutDaysRequest(String setName, List<String> days) {}