import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/account/intro_page.dart';

class FoodService {
  final AuthService authService;
  final BuildContext context;

  FoodService(this.authService, this.context);

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

  Future<List<Map<String, dynamic>>> getFoodsByDay(String day) async {
    await _handleTokenExpiry();
    final response = await authService.dio.get("/DietDay/$day");
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data);
    }
    throw Exception("Error fetching foods: ${response.statusCode}");
  }

  Future<void> addFood(String day, Map<String, dynamic> food) async {
    await _handleTokenExpiry();
    final response = await authService.dio.post(
      "/DietDay/$day",
      data: jsonEncode(food),
    );
    if (response.statusCode != 200) {
      throw Exception("Error adding food: ${response.statusCode}");
    }
  }

  Future<void> updateFood(String day, int foodId, Map<String, dynamic> food) async {
    await _handleTokenExpiry();
    final response = await authService.dio.put(
      "/DietDay/$day/$foodId",
      data: jsonEncode(food),
    );
    if (response.statusCode != 200) {
      throw Exception("Error updating food: ${response.statusCode}");
    }
  }

  Future<void> deleteFood(String day, int foodId) async {
    await _handleTokenExpiry();
    final response = await authService.dio.delete("/DietDay/$day/$foodId");
    if (response.statusCode != 204) {
      throw Exception("Error deleting food: ${response.statusCode}");
    }
  }
}