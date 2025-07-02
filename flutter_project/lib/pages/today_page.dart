import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/auth.dart';
import 'package:flutter_project/pages/services/weekly.dart';
import 'package:flutter_project/pages/services/food.dart';
import 'package:flutter_project/pages/workout/workout_splits.dart';
import 'package:flutter_project/pages/diet/food_diary.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({Key? key}) : super(key: key);

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late final WeeklyService _weeklyService;
  late final FoodService _foodService;
  late final AuthService _authService;
  List<Map<String, dynamic>> _todayWorkouts = [];
  List<Map<String, dynamic>> _todayMeals = [];
  bool _isLoading = true;
  bool _isMealsLoading = true;
  String? _errorMessage;
  String? _mealsErrorMessage;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _weeklyService = WeeklyService(_authService, context);
    _foodService = FoodService(_authService, context);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isMealsLoading = true;
      _errorMessage = null;
      _mealsErrorMessage = null;
    });

    try {
      final today = _getCurrentDay();
      final workouts = await _weeklyService.getWorkoutByDay(today);
      final meals = await _foodService.getFoodsByDay(today);
      
      setState(() {
        _todayWorkouts = workouts;
        _todayMeals = meals;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data';
        _mealsErrorMessage = 'Failed to load meals';
      });
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isMealsLoading = false;
      });
    }
  }

  String _getCurrentDay() {
    final now = DateTime.now();
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[now.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildWorkoutSection(),
              _buildMealSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutSection() {
    final groupedWorkouts = <String, List<Map<String, dynamic>>>{};
    for (var group in WorkoutConstants.muscleGroups) {
      groupedWorkouts[group] = [];
    }

    for (var workout in _todayWorkouts) {
      final group = workout['grupo_muscular'] ?? 'other';
      if (groupedWorkouts.containsKey(group)) {
        groupedWorkouts[group]!.add(workout);
      } else {
        groupedWorkouts['other']!.add(workout);
      }
    }

    groupedWorkouts.removeWhere((key, value) => value.isEmpty);
    final sortedGroups = WorkoutConstants.muscleGroups
        .where((group) => groupedWorkouts.containsKey(group))
        .toList();

    // Determinar qual split está sendo usado hoje
    String? currentSplit;
    if (_todayWorkouts.isNotEmpty) {
      currentSplit = _todayWorkouts.first['split'] ?? 'A'; // Assume 'A' como padrão se não houver split definido
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Workout",
                  style: TextStyle(fontSize: 22),
                ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutSplitsPage(),
                          settings: RouteSettings(
                            arguments: currentSplit,
                          ),
                        ),
                      ).then((_) {
                        _loadData(); // Recarrega dados ao voltar
                      });
                    },
                    child: const Text(
                      'See More',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.deepPurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _todayWorkouts.isEmpty
                        ? const Center(child: Text('No workouts for today', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedGroups.length,
                            itemBuilder: (context, index) {
                              return _MuscleGroupCard(
                                groupName: sortedGroups[index],
                                exercises: groupedWorkouts[sortedGroups[index]]!,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    final groupedMeals = <String, List<Map<String, dynamic>>>{};
    for (var type in NutritionConstants.mealTypes) {
      groupedMeals[type] = [];
    }

    for (var meal in _todayMeals) {
      final type = meal['tipo_alimento'] ?? 'other';
      if (groupedMeals.containsKey(type)) {
        groupedMeals[type]!.add(meal);
      } else {
        groupedMeals['other']!.add(meal);
      }
    }

    groupedMeals.removeWhere((key, value) => value.isEmpty);
    final sortedMealTypes = NutritionConstants.mealTypes
        .where((type) => groupedMeals.containsKey(type))
        .toList();

    // Obter o dia atual no formato 'Mon', 'Tue', etc.
    final currentDay = _getCurrentDay();

    return Container(
      padding: const EdgeInsets.only(top: 8),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Nutrition",
                  style: TextStyle(fontSize: 22),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodDiaryPage(),
                        settings: RouteSettings(
                          arguments: currentDay,
                        ),
                      ),
                    ).then((_) {
                      _loadData(); // Recarrega dados ao voltar
                    });
                  },
                  child: const Text(
                    'See More',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isMealsLoading
                ? const Center(child: CircularProgressIndicator())
                : _mealsErrorMessage != null
                    ? Center(child: Text(_mealsErrorMessage!, style: const TextStyle(color: Colors.red)))
                    : _todayMeals.isEmpty
                        ? const Center(child: Text('No meals recorded today', style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedMealTypes.length,
                            itemBuilder: (context, index) {
                              return _MealTypeCard(
                                mealType: sortedMealTypes[index],
                                meals: groupedMeals[sortedMealTypes[index]]!,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupCard extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> exercises;

  const _MuscleGroupCard({
    required this.groupName,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                _formatGroupName(groupName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _ExerciseCard(exercise: exercises[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGroupName(String group) {
    return group
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}

class _MealTypeCard extends StatelessWidget {
  final String mealType;
  final List<Map<String, dynamic>> meals;

  const _MealTypeCard({
    required this.mealType,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                _formatMealType(mealType),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: meals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _MealCard(meal: meals[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMealType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> exercise;

  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exercise['nome'] ?? 'No name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${exercise['series']}x${exercise['repeticoes']}',
                  style: TextStyle(
                    color: Colors.deepPurple.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (exercise['peso'] != null && exercise['peso'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${exercise['peso']} kg',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          if (exercise['tempo'] != null && exercise['tempo'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${exercise['tempo']} min rest',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          if (exercise['anotacao'] != null && exercise['anotacao'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise['anotacao'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  meal['alimento'] ?? 'No name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meal['horario'] ?? '--:--',
                  style: TextStyle(
                    color: Colors.deepPurple.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (meal['peso'] != null && meal['peso'] > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.scale_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${meal['peso']}g',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (meal['anotacao'] != null && meal['anotacao'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal['anotacao'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}