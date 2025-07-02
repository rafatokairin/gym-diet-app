import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/account/intro_page.dart';

class WorkoutService {
  final AuthService authService;
  final BuildContext context;

  WorkoutService(this.authService, this.context);

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

  Future<List<Map<String, dynamic>>> getExercises(String split) async {
    await _handleTokenExpiry();
    final response = await authService.dio.get("/WorkoutSet/$split");
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    throw Exception("Error fetching exercises: ${response.statusCode}");
  }

  Future<void> addExercise(String split, Map<String, dynamic> exercise) async {
    await _handleTokenExpiry();
    final response = await authService.dio.post(
      "/WorkoutSet/$split",
      data: jsonEncode(exercise),
    );
    if (response.statusCode != 200) {
      throw Exception("Error adding exercise: ${response.statusCode}");
    }
  }

  Future<void> updateExercise(String split, int id, Map<String, dynamic> exercise) async {
    await _handleTokenExpiry();
    final response = await authService.dio.put(
      "/WorkoutSet/$split/$id",
      data: jsonEncode(exercise),
    );
    if (response.statusCode != 200) {
      throw Exception("Error updating exercise: ${response.statusCode}");
    }
  }

  Future<void> deleteExercise(String split, int id) async {
    await _handleTokenExpiry();
    final response = await authService.dio.delete("/WorkoutSet/$split/$id");
    if (response.statusCode != 204) {
      throw Exception("Error deleting exercise: ${response.statusCode}");
    }
  }
}