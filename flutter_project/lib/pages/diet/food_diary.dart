import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/food.dart';
import 'package:flutter_project/pages/services/tdee.dart';
import 'package:flutter_project/pages/services/auth.dart';

// List of meal types in chronological order
class NutritionConstants {
  static const List<String> mealTypes = [
    'breakfast',
    'morning_snack',
    'pre_workout',
    'post_workout',
    'lunch',
    'afternoon_snack',
    'dinner',
    'supper',
    'other'
  ];
}

// Function to format meal type for display
String formatMealType(String type) {
  if (type.isEmpty) return type;
  
  return type
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty 
          ? word[0].toUpperCase() + word.substring(1) 
          : '')
      .join(' ');
}

class FoodDiaryPage extends StatefulWidget {
  const FoodDiaryPage({super.key});

  @override
  State<FoodDiaryPage> createState() => _FoodDiaryPageState();
}

class _FoodDiaryPageState extends State<FoodDiaryPage> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  int selectedDayIndex = 0;

  final AuthService authService = AuthService();
  late FoodService foodService;
  late UserGCDService userGCDService;

  Map<String, List<Map<String, dynamic>>> mealsByDay = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  // TDEE targets
  Map<String, int> tdeeTargets = {};
  bool hasTDEE = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    foodService = FoodService(authService, context);
    userGCDService = UserGCDService(authService, context);
    // Definir o dia padrão como o dia atual
    selectedDayIndex = (DateTime.now().weekday - 1) % 7;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar se recebemos um argumento com o dia a ser exibido
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is String) {
      final dayIndex = days.indexOf(routeArgs);
      if (dayIndex != -1) {
        selectedDayIndex = dayIndex;
      }
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        hasTDEE = false;
      });
    }

    try {
      final Map<String, List<Map<String, dynamic>>> updatedMeals = {};
      
      // Load meals for each day
      for (final day in days) {
        final meals = await foodService.getFoodsByDay(day);
        updatedMeals[day] = meals;
      }
      
      // Try to load GCD data (optional)
      try {
        final gcdData = await userGCDService.getUserGCD();
        if (gcdData.isNotEmpty && mounted) {
          setState(() {
            tdeeTargets = {
              'carboidratos_gcd': gcdData['carboidratos_gcd']?.toInt() ?? 0,
              'proteinas_gcd': gcdData['proteinas_gcd']?.toInt() ?? 0,
              'fibras_gcd': gcdData['fibras_gcd']?.toInt() ?? 0,
              'gorduras_gcd': gcdData['gorduras_gcd']?.toInt() ?? 0,
              'gcd': gcdData['gcd']?.toInt() ?? 0,
            };
            hasTDEE = true;
          });
        }
      } catch (e) {
        print("GCD data not available: $e");
      }

      if (mounted) {
        setState(() {
          mealsByDay = updatedMeals;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading from API: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(controller.text) ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = _formatTime(picked);
    }
  }

  TimeOfDay? _parseTime(String time) {
    if (time == '--:--') return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteMeal(int id) async {
    try {
      final day = days[selectedDayIndex];
      
      // Update local state first for immediate response
      setState(() {
        mealsByDay[day] = mealsByDay[day]!.where((meal) => meal['id'] != id).toList();
      });
      
      // Then call API
      await foodService.deleteFood(day, id);
      
      // Reload data to ensure sync with backend
      await _loadData();
    } catch (e) {
      print("Error deleting meal: $e");
      // If error, reload to restore state
      await _loadData();
    }
  }

  Future<void> _editMeal(int id, Map<String, dynamic> updatedMeal) async {
    try {
      final day = days[selectedDayIndex];
      
      // Update locally first
      setState(() {
        mealsByDay[day] = mealsByDay[day]!.map((meal) {
          return meal['id'] == id ? {...meal, ...updatedMeal} : meal;
        }).toList();
      });
      
      // Then sync with backend
      await foodService.updateFood(day, id, updatedMeal);
      await _loadData();
    } catch (e) {
      print("Error editing meal: $e");
      await _loadData();
    }
  }

  Future<void> _addMeal(Map<String, dynamic> newMeal) async {
    try {
      final day = days[selectedDayIndex];
      
      // Add locally first (with temporary ID)
      setState(() {
        mealsByDay[day] = [...mealsByDay[day]!, {...newMeal, 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'}];
      });
      
      // Then sync with backend
      await foodService.addFood(day, newMeal);
      await _loadData();
    } catch (e) {
      print("Error adding meal: $e");
      await _loadData();
    }
  }

  int _calculateCalories(Map<String, dynamic> meal) {
    final carboidratos = (meal['carboidratos'] as num).toInt();
    final proteinas = (meal['proteinas'] as num).toInt();
    final gorduras = (meal['gorduras'] as num).toInt();
    return (carboidratos * 4) + (proteinas * 4) + (gorduras * 9);
  }

  Widget _buildMacroRow({
    required String label,
    required int value,
    required int target,
    required Color color,
  }) {
    final percentage = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '$value / $target ${label == 'Calories' ? 'kcal' : 'g'}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentDay = days[selectedDayIndex];
    final meals = List<Map<String, dynamic>>.from(mealsByDay[currentDay] ?? []);

    // Sort all meals by time first
    meals.sort((a, b) {
      final timeA = a['horario'] ?? '';
      final timeB = b['horario'] ?? '';
      return timeA.compareTo(timeB);
    });

    // Group meals by meal type in chronological order
    final Map<String, List<Map<String, dynamic>>> groupedMeals = {};
    // Initialize with all meal types in order
    for (var type in NutritionConstants.mealTypes) {
      groupedMeals[type] = [];
    }

    // Add meals to their respective groups
    for (var meal in meals) {
      final mealType = meal['tipo_alimento'] ?? 'other';
      if (groupedMeals.containsKey(mealType)) {
        groupedMeals[mealType]!.add(meal);
      } else {
        groupedMeals['other']!.add(meal);
      }
    }

    // Remove empty meal types
    groupedMeals.removeWhere((key, value) => value.isEmpty);

    // Calculate totals
    int totalCarbs = 0;
    int totalProteins = 0;
    int totalFiber = 0;
    int totalFats = 0;
    int totalCalories = 0;

    for (var meal in meals) {
      totalCarbs += (meal['carboidratos'] as num).toInt();
      totalProteins += (meal['proteinas'] as num).toInt();
      totalFiber += (meal['fibras'] as num).toInt();
      totalFats += (meal['gorduras'] as num).toInt();
      totalCalories += _calculateCalories(meal);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary'),
      ),
      body: Column(
        children: [
          // Day selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: List.generate(days.length, (index) {
                final isSelected = selectedDayIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          
          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : (meals.isEmpty
                    ? const Center(child: Text('No food added.'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          // Show meal groups in chronological order
                          ...NutritionConstants.mealTypes.where((type) => groupedMeals.containsKey(type)).map((type) {
                            final mealsInGroup = groupedMeals[type]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    formatMealType(type),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...mealsInGroup.map((meal) {
                                  return InkWell(
                                    onTap: () {
                                      _showEditDialog(context, meal);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
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
                                                    meal['horario']?.isNotEmpty == true ? meal['horario'] : '--:--',
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
                                            // Nutrition info chips
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  if (meal['carboidratos'] != null && meal['carboidratos'] > 0)
                                                    Chip(
                                                      backgroundColor: Colors.green.shade50,
                                                      label: Text(
                                                        'Carbs: ${meal['carboidratos']}g',
                                                        style: TextStyle(
                                                          color: Colors.green.shade800,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                  if (meal['proteinas'] != null && meal['proteinas'] > 0)
                                                    Chip(
                                                      backgroundColor: Colors.orange.shade50,
                                                      label: Text(
                                                        'Protein: ${meal['proteinas']}g',
                                                        style: TextStyle(
                                                          color: Colors.orange.shade800,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                  if (meal['gorduras'] != null && meal['gorduras'] > 0)
                                                    Chip(
                                                      backgroundColor: Colors.red.shade50,
                                                      label: Text(
                                                        'Fat: ${meal['gorduras']}g',
                                                        style: TextStyle(
                                                          color: Colors.red.shade800,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                  if (meal['fibras'] != null && meal['fibras'] > 0)
                                                    Chip(
                                                      backgroundColor: Colors.brown.shade50,
                                                      label: Text(
                                                        'Fiber: ${meal['fibras']}g',
                                                        style: TextStyle(
                                                          color: Colors.brown.shade800,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      visualDensity: VisualDensity.compact,
                                                    ),
                                                ],
                                              ),
                                            ),
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
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                          
                          // TDEE warning
                          if (!hasTDEE && !isLoading)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange[800]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Set your goals in the TDEE calculator to track progress',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Daily totals
                          if (hasTDEE)
                            Card(
                              color: Colors.blue.shade50,
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Daily Totals',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMacroRow(
                                      label: 'Calories',
                                      value: totalCalories,
                                      target: tdeeTargets['gcd']!,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMacroRow(
                                      label: 'Carbohydrates',
                                      value: totalCarbs,
                                      target: tdeeTargets['carboidratos_gcd']!,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildMacroRow(
                                      label: 'Proteins',
                                      value: totalProteins,
                                      target: tdeeTargets['proteinas_gcd']!,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildMacroRow(
                                      label: 'Fats',
                                      value: totalFats,
                                      target: tdeeTargets['gorduras_gcd']!,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildMacroRow(
                                      label: 'Fiber',
                                      value: totalFiber,
                                      target: tdeeTargets['fibras_gcd']!,
                                      color: Colors.brown,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog(context);
        },
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withAlpha((255 * 0.6).toInt()),
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

void _showEditDialog(BuildContext context, Map<String, dynamic> meal) {
    String selectedMealType = meal['tipo_alimento'] ?? '';
    final nameController = TextEditingController(text: meal['alimento']);
    final weightController = TextEditingController(text: meal['peso'].toString());
    final carbsController = TextEditingController(text: meal['carboidratos'].toString());
    final proteinsController = TextEditingController(text: meal['proteinas'].toString());
    final fiberController = TextEditingController(text: meal['fibras'].toString());
    final fatsController = TextEditingController(text: meal['gorduras'].toString());
    final timeController = TextEditingController(text: meal['horario']?.isNotEmpty == true ? meal['horario'] : '--:--');
    final notesController = TextEditingController(text: meal['anotacao']);

    // Variável para controlar o estado do checkbox
    bool lockMacros = false;
    // Peso original para cálculos de proporção
    double originalWeight = meal['peso']?.toDouble() ?? 100.0;
    // Valores originais dos macros
    final originalMacros = {
      'carbs': meal['carboidratos']?.toDouble() ?? 0.0,
      'proteins': meal['proteinas']?.toDouble() ?? 0.0,
      'fiber': meal['fibras']?.toDouble() ?? 0.0,
      'fats': meal['gorduras']?.toDouble() ?? 0.0,
    };

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Função para ajustar os macros baseado no peso
            void adjustMacros() {
              if (!lockMacros) return;
              
              final newWeight = double.tryParse(weightController.text) ?? originalWeight;
              final ratio = newWeight / originalWeight;
              
              carbsController.text = (originalMacros['carbs']! * ratio).toStringAsFixed(1);
              proteinsController.text = (originalMacros['proteins']! * ratio).toStringAsFixed(1);
              fiberController.text = (originalMacros['fiber']! * ratio).toStringAsFixed(1);
              fatsController.text = (originalMacros['fats']! * ratio).toStringAsFixed(1);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Meal',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedMealType.isNotEmpty ? selectedMealType : null,
                                decoration: const InputDecoration(labelText: 'Meal Type'),
                                items: NutritionConstants.mealTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(formatMealType(type)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedMealType = value;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a meal type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Food Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a food name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: weightController,
                                    decoration: const InputDecoration(labelText: 'Weight (g)'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (lockMacros) {
                                        adjustMacros();
                                      }
                                    },
                                  ),
                                ),
                                Checkbox(
                                  value: lockMacros,
                                  onChanged: (value) {
                                    setState(() {
                                      lockMacros = value ?? false;
                                      if (lockMacros) {
                                        // Quando ativado, salva os valores originais
                                        originalWeight = double.tryParse(weightController.text) ?? 100.0;
                                        if (weightController.text.isEmpty) {
                                          weightController.text = '100'; // Define 100g como padrão
                                        }
                                        originalMacros['carbs'] = double.tryParse(carbsController.text) ?? 0.0;
                                        originalMacros['proteins'] = double.tryParse(proteinsController.text) ?? 0.0;
                                        originalMacros['fiber'] = double.tryParse(fiberController.text) ?? 0.0;
                                        originalMacros['fats'] = double.tryParse(fatsController.text) ?? 0.0;
                                        adjustMacros();
                                      }
                                    });
                                  },
                                ),
                                const Text('Lock Macros'),
                              ],
                            ),
                            // Adicione este texto informativo
                            if (lockMacros)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Using default reference: 100g',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: carbsController,
                                decoration: const InputDecoration(labelText: 'Carbohydrates (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: proteinsController,
                                decoration: const InputDecoration(labelText: 'Proteins (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: fiberController,
                                decoration: const InputDecoration(labelText: 'Fibers (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: fatsController,
                                decoration: const InputDecoration(labelText: 'Fats (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: timeController,
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.access_time),
                                    onPressed: () => _selectTime(context, timeController),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () => _selectTime(context, timeController),
                                validator: (value) {
                                  if (value == null || value.isEmpty || value == '--:--') {
                                    return 'Please select a time';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 150,
                                ),
                                child: TextField(
                                  controller: notesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteMeal(meal['id']);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  final updatedMeal = {
                                    'tipo_alimento': selectedMealType,
                                    'alimento': nameController.text,
                                    'peso': int.tryParse(weightController.text) ?? 0,
                                    'carboidratos': double.tryParse(carbsController.text)?.round() ?? 0,
                                    'proteinas': double.tryParse(proteinsController.text)?.round() ?? 0,
                                    'fibras': double.tryParse(fiberController.text)?.round() ?? 0,
                                    'gorduras': double.tryParse(fatsController.text)?.round() ?? 0,
                                    'horario': timeController.text,
                                    'anotacao': notesController.text,
                                  };
                                  _editMeal(meal['id'], updatedMeal);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Implementação similar para _showAddDialog
  void _showAddDialog(BuildContext context) {
    String selectedMealType = '';
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final carbsController = TextEditingController();
    final proteinsController = TextEditingController();
    final fiberController = TextEditingController();
    final fatsController = TextEditingController();
    final timeController = TextEditingController(text: '--:--');
    final notesController = TextEditingController();
    
    // Variáveis para o checkbox de lock
    bool lockMacros = false;
    double originalWeight = 100.0;
    final originalMacros = {
      'carbs': 0.0,
      'proteins': 0.0,
      'fiber': 0.0,
      'fats': 0.0,
    };

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Função para ajustar os macros baseado no peso
            void adjustMacros() {
              if (!lockMacros) return;
              
              final newWeight = double.tryParse(weightController.text) ?? originalWeight;
              final ratio = newWeight / originalWeight;
              
              carbsController.text = (originalMacros['carbs']! * ratio).toStringAsFixed(1);
              proteinsController.text = (originalMacros['proteins']! * ratio).toStringAsFixed(1);
              fiberController.text = (originalMacros['fiber']! * ratio).toStringAsFixed(1);
              fatsController.text = (originalMacros['fats']! * ratio).toStringAsFixed(1);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 600,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8, top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Meal',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedMealType.isNotEmpty ? selectedMealType : null,
                                decoration: const InputDecoration(labelText: 'Meal Type'),
                                items: NutritionConstants.mealTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(formatMealType(type)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedMealType = value;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a meal type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Food Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a food name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: weightController,
                                    decoration: const InputDecoration(labelText: 'Weight (g)'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      if (lockMacros) {
                                        adjustMacros();
                                      }
                                    },
                                  ),
                                ),
                                Checkbox(
                                  value: lockMacros,
                                  onChanged: (value) {
                                    setState(() {
                                      lockMacros = value ?? false;
                                      if (lockMacros) {
                                        // Quando ativado, salva os valores originais
                                        originalWeight = double.tryParse(weightController.text) ?? 100.0;
                                        if (weightController.text.isEmpty) {
                                          weightController.text = '100'; // Define 100g como padrão
                                        }
                                        originalMacros['carbs'] = double.tryParse(carbsController.text) ?? 0.0;
                                        originalMacros['proteins'] = double.tryParse(proteinsController.text) ?? 0.0;
                                        originalMacros['fiber'] = double.tryParse(fiberController.text) ?? 0.0;
                                        originalMacros['fats'] = double.tryParse(fatsController.text) ?? 0.0;
                                        adjustMacros();
                                      }
                                    });
                                  },
                                ),
                                const Text('Lock Macros'),
                              ],
                            ),
                            // Adicione este texto informativo
                            if (lockMacros)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Using default reference: 100g',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: carbsController,
                                decoration: const InputDecoration(labelText: 'Carbohydrates (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: proteinsController,
                                decoration: const InputDecoration(labelText: 'Proteins (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: fiberController,
                                decoration: const InputDecoration(labelText: 'Fibers (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: fatsController,
                                decoration: const InputDecoration(labelText: 'Fats (g)'),
                                keyboardType: TextInputType.number,
                                enabled: !lockMacros,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: timeController,
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.access_time),
                                    onPressed: () => _selectTime(context, timeController),
                                  ),
                                ),
                                readOnly: true,
                                onTap: () => _selectTime(context, timeController),
                                validator: (value) {
                                  if (value == null || value.isEmpty || value == '--:--') {
                                    return 'Please select a time';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 150,
                                ),
                                child: TextField(
                                  controller: notesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Notes',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  final newMeal = {
                                    'tipo_alimento': selectedMealType,
                                    'alimento': nameController.text,
                                    'peso': int.tryParse(weightController.text) ?? 0,
                                    'carboidratos': double.tryParse(carbsController.text)?.round() ?? 0,
                                    'proteinas': double.tryParse(proteinsController.text)?.round() ?? 0,
                                    'fibras': double.tryParse(fiberController.text)?.round() ?? 0,
                                    'gorduras': double.tryParse(fatsController.text)?.round() ?? 0,
                                    'horario': timeController.text,
                                    'anotacao': notesController.text,
                                  };
                                  _addMeal(newMeal);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}