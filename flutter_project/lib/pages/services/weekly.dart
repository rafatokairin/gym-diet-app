import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/account/intro_page.dart';

class WeeklyService {
  final AuthService authService;
  final BuildContext context;

  WeeklyService(this.authService, this.context);

  Future<void> _handleTokenExpiry() async {
    try {
      final isValid = await authService.isTokenValid();
      if (!isValid) {
        final refreshed = await authService.refreshToken();
        if (!refreshed) {
          _redirectToLogin();
        }
      }
    } catch (e) {
      _redirectToLogin();
      throw Exception('Authentication failed');
    }
  }

  void _redirectToLogin() {
    authService.clearTokens();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<List<Map<String, dynamic>>> getUserWorkouts() async {
    await _handleTokenExpiry();
    final response = await authService.dio.get("/workouts");
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    throw Exception("Error fetching workouts: ${response.statusCode}");
  }

Future<List<Map<String, dynamic>>> getWorkoutByDay(String day) async {
  await _handleTokenExpiry();
  try {
    final response = await authService.dio.get("/workouts/$day");
    if (response.statusCode == 200) {
      final workouts = List<Map<String, dynamic>>.from(response.data);
      // Adicionar o split a cada exercício
      final userWorkouts = await getUserWorkouts();
      final workoutForDay = userWorkouts.firstWhere(
        (workout) => workout['days'].contains(day),
        orElse: () => {'setName': 'A'}, // Padrão para 'A' se não encontrado
      );
      
      return workouts.map((exercise) => {
        ...exercise,
        'split': workoutForDay['setName'],
      }).toList();
    }
    throw Exception("Error fetching workout for day $day: ${response.statusCode}");
  } catch (e) {
    print("Error in getWorkoutByDay: $e");
    rethrow;
  }
}

  Future<void> updateWorkoutDays({
    required String workoutName,
    required List<String> days,
  }) async {
    await _handleTokenExpiry();
    final response = await authService.dio.post(
      "/workouts/set-days",
      data: jsonEncode({
        "setName": workoutName,
        "days": days,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Error updating workout days: ${response.statusCode}");
    }
  }
}

class UserWorkout {
  final String workoutName;
  final List<String> days;

  UserWorkout({required this.workoutName, required this.days});

  factory UserWorkout.fromJson(Map<String, dynamic> json) {
    return UserWorkout(
      workoutName: json['workoutName'],
      days: List<String>.from(json['days']),
    );
  }
}