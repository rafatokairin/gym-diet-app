import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/account/intro_page.dart';

class UserGCDService {
  final AuthService authService;
  final BuildContext context;

  UserGCDService(this.authService, this.context);

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

  Future<Map<String, dynamic>> getUserGCD() async {
    await _handleTokenExpiry();
    final response = await authService.dio.get("/UserGcd");
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception("Error fetching UserGCD: ${response.statusCode}");
  }

  Future<void> addUserGCD(Map<String, dynamic> userGCD) async {
    await _handleTokenExpiry();
    final response = await authService.dio.post(
      "/UserGcd",
      data: jsonEncode(userGCD),
    );
    if (response.statusCode != 200) {
      throw Exception("Error adding UserGCD: ${response.statusCode}");
    }
  }

  Future<void> updateUserGCD(Map<String, dynamic> updatedGCD) async {
    await _handleTokenExpiry();
    final response = await authService.dio.put(
      "/UserGcd",
      data: jsonEncode(updatedGCD),
    );
    if (response.statusCode != 200) {
      throw Exception("Error updating UserGCD: ${response.statusCode}");
    }
  }

  Future<void> deleteUserGCD() async {
    await _handleTokenExpiry();
    final response = await authService.dio.delete("/UserGcd");
    
    if (response.statusCode != 204) {
      throw Exception("Error deleting UserGCD: ${response.statusCode}");
    }
  }
}