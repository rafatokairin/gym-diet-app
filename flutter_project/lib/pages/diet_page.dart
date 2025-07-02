import 'package:flutter/material.dart';
import 'package:flutter_project/pages/diet/food_diary.dart';
import 'package:flutter_project/pages/diet/tdee_calculator.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  final List<String> dietOptions = [
    'TDEE Calculator',
    'Food Diary',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        itemCount: dietOptions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 per row
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3, // button width/heigth
        ),
        itemBuilder: (context, index) {
          return ElevatedButton(
            onPressed: () {
              if (dietOptions[index] == 'Food Diary') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodDiaryPage()),
                );
              }
              // Se quiser adicionar outra navegação para 'TDEE Calculator', faça o mesmo aqui.
              if (dietOptions[index] == 'TDEE Calculator') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TDEECalculatorPage()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(dietOptions[index]),
          );
        },
      ),
    );
  }
}
