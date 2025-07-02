import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_project/main.dart';
import 'package:flutter_project/pages/account/intro_page.dart';

class AuthService {
  final Dio dio;
  final Dio refreshDio;
  final storage = const FlutterSecureStorage();

  AuthService()
      : dio = Dio(BaseOptions(
          baseUrl: "http://192.168.0.112:8080",
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        )),
        refreshDio = Dio(BaseOptions(
          baseUrl: "http://192.168.0.112:8080",
          headers: {"Content-Type": "application/json"},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioError error, handler) async {
        if ((error.response?.statusCode == 401 || error.response?.statusCode == 403) &&
            !error.requestOptions.path.contains('/auth/refresh')) {
          try {
            final success = await refreshToken();
            if (success) {
              final newToken = await storage.read(key: "access_token");
              error.requestOptions.headers["Authorization"] = "Bearer $newToken";
              return handler.resolve(await dio.fetch(error.requestOptions));
            }
          } catch (e) {
            print('Erro durante renovação de token: $e');
            await _redirectToLogin();
            return handler.reject(error);
          }
          await _redirectToLogin();
          return handler.reject(error);
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> _redirectToLogin() async {
    await clearTokens();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Future<bool> login(String email, String password) async {
    final response = await dio.post("/auth/login", data: jsonEncode({
      "login": email,
      "password": password,
    }));

    if (response.statusCode == 200) {
      await _saveTokens(response.data);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await dio.post("/auth/logout");
    } finally {
      await clearTokens();
      _redirectToLogin();
    }
  }

  Future<bool> isTokenValid() async {
    try {
      final response = await dio.get("/auth/validate");
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshToken() async {
    final refreshToken = await storage.read(key: "refresh_token");
    if (refreshToken == null) {
      throw Exception('Refresh token not found');
    }

    try {
      final response = await refreshDio.post(
        "/auth/refresh",
        data: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        await _saveTokens(response.data);
        return true;
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      print('Erro ao renovar token: $e');
      throw Exception('Failed to refresh token');
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    await storage.write(key: "access_token", value: tokens["access_token"]);
    await storage.write(key: "refresh_token", value: tokens["refresh_token"]);
  }

  Future<void> clearTokens() async {
    await storage.delete(key: "access_token");
    await storage.delete(key: "refresh_token");
  }
}