import 'package:flutter/material.dart';
import 'package:flutter_project/pages/workout/weekly_plan.dart';
import 'package:flutter_project/pages/workout/workout_splits.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<String> workoutOptions = [
    'Weekly Plan',
    'Workout Splits',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: workoutOptions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 per row
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3, // button width/heigth
        ),
        itemBuilder: (context, index) {
          return ElevatedButton(
            onPressed: () {
              if (workoutOptions[index] == 'Workout Splits') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutSplitsPage()),
                );
              }
              if (workoutOptions[index] == 'Weekly Plan') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeeklyPlanPage()),
                );
              }
              // Se quiser adicionar outra navegação para 'TDEE Calculator', faça o mesmo aqui.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(workoutOptions[index]),
          );
        },
      ),
    );
  }
}