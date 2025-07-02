import 'package:flutter/material.dart';
import 'package:flutter_project/components/bottom_nav_bar.dart';
import 'package:flutter_project/pages/diet_page.dart';
import 'package:flutter_project/pages/profile_page.dart';
import 'package:flutter_project/pages/today_page.dart';
import 'package:flutter_project/pages/workout_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // index to control bottom nav bar
  int _selectedIndex = 0;
  
  // method to update index
  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // pages to display
  final List<Widget> _pages = [
    const TodayPage(),
    const DietPage(),
    const WorkoutPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Verificar se o token está armazenado corretamente
    final storage = FlutterSecureStorage();
    storage.read(key: 'access_token').then((token) {
      print("Token armazenado na HomePage: $token");
    });

    return Scaffold(
      backgroundColor: Colors.grey[300],
      bottomNavigationBar: MyBottomNavBar(
        onTabChange: (index) => navigateBottomBar(index),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
