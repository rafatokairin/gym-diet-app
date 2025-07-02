import 'package:flutter/material.dart';
import 'package:flutter_project/pages/account/intro_page.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Pequeno delay para exibir a splash screen
      await Future.delayed(const Duration(seconds: 1));

      // Verifica se temos um token de acesso
      final accessToken = await _authService.storage.read(key: "access_token");
      final refreshToken = await _authService.storage.read(key: "refresh_token");

      if (accessToken == null || refreshToken == null) {
        _goToLogin();
        return;
      }

      // Verifica se o token atual é válido
      final isValid = await _authService.isTokenValid();
      
      if (isValid) {
        _goToHome();
        return;
      }

      // Se o token não é válido, tenta renovar
      final refreshed = await _authService.refreshToken();
      
      if (refreshed) {
        _goToHome();
      } else {
        await _authService.logout();
        _goToLogin();
      }
    } catch (e) {
      // Em caso de qualquer erro, vai para a tela de login
      _goToLogin();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}