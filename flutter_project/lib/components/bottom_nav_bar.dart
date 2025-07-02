import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MyBottomNavBar extends StatelessWidget {
  final void Function(int)? onTabChange;
  const MyBottomNavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GNav(
        color: Colors.grey[400],
        activeColor: Colors.grey.shade700,
        tabActiveBorder: Border.all(color: Colors.white),
        tabBackgroundColor: Colors.grey.shade100,
        gap: 8,  
        padding: const EdgeInsets.all(12),
        tabMargin: const EdgeInsets.symmetric(vertical: 8),
        tabBorderRadius: 16,
        iconSize: 26,  
        textStyle: const TextStyle(
          fontSize: 14,  
          fontWeight: FontWeight.w500,
        ),
        mainAxisAlignment: MainAxisAlignment.spaceAround,  
        onTabChange: (value) => onTabChange!(value),
        tabs: const [
          GButton(
            icon: Icons.home,
            text: 'Home',
          ),
          GButton(
            icon: Icons.restaurant,
            text: 'Diet',
          ),
          GButton(
            icon: Icons.fitness_center,
            text: 'Workout',
          ),
          GButton(
            icon: Icons.person,
            text: 'Profile',
          ),
        ],
      ),
    );
  }
}
