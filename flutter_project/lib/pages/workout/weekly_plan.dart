import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/weekly.dart';
import 'package:flutter_project/pages/services/auth.dart';

class WeeklyPlanPage extends StatefulWidget {
  const WeeklyPlanPage({Key? key}) : super(key: key);

  @override
  _WeeklyPlanPageState createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends State<WeeklyPlanPage> {
  final AuthService authService = AuthService();
  late WeeklyService _weeklyService;
  bool _isLoading = true;
  String? _errorMessage;

  // Lista de treinos disponíveis
  final List<String> _workouts = ['A', 'B', 'C', 'D', 'E'];
  final Map<String, Color> _workoutColors = {
    'A': Colors.blue,
    'B': Colors.orange,
    'C': Colors.green,
    'D': Colors.red,
    'E': Colors.purple,
  };

  String? _selectedWorkout;
  final Map<int, String> _assignment = {};
  static const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _weeklyService = WeeklyService(authService, context);
    _loadUserWorkouts();
  }

  Future<void> _loadUserWorkouts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final workouts = await _weeklyService.getUserWorkouts();
      
      // Limpa atribuições anteriores
      _assignment.clear();
      
      // Preenche os dias atribuídos
      for (final workout in workouts) {
        final workoutName = workout['setName'] as String;
        final days = List<String>.from(workout['days'] ?? []);
        
        for (final day in days) {
          final dayIndex = _days.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
          if (dayIndex != -1) {
            _assignment[dayIndex] = workoutName;
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load workouts: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDayTap(int index) {
    if (_selectedWorkout == null) {
      // Se nenhum treino está selecionado, remove a atribuição do dia
      if (_assignment.containsKey(index)) {
        setState(() {
          _assignment.remove(index);
        });
      }
      return;
    }

    final assigned = _assignment[index];
    if (assigned == null) {
      setState(() {
        _assignment[index] = _selectedWorkout!;
      });
    } else if (assigned == _selectedWorkout) {
      setState(() {
        _assignment.remove(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Day already assigned to $assigned')),
      );
    }
  }

  Future<void> _savePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Agrupa dias por treino
      final Map<String, List<String>> workoutDays = {};
      for (final entry in _assignment.entries) {
        final workout = entry.value;
        final day = _days[entry.key];
        workoutDays.putIfAbsent(workout, () => []).add(day);
      }

      // Envia cada treino para a API
      for (final workout in _workouts) {
        final days = workoutDays[workout] ?? [];
        await _weeklyService.updateWorkoutDays(
          workoutName: workout,
          days: days,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved successfully!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save plan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plan'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const Text(
                      'Select Workout:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _workouts.map((w) {
                        final isSelected = _selectedWorkout == w;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedWorkout = isSelected ? null : w;
                                });
                              },
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _workoutColors[w]!.withOpacity(0.6)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    w,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Assign Days:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_days.length, (i) {
                        final workout = _assignment[i];
                        final color = workout != null 
                            ? _workoutColors[workout] ?? Colors.blue
                            : Colors.grey.shade200;
                        final textColor = workout != null ? Colors.white : Colors.black;
                        
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: GestureDetector(
                              onTap: () => _onDayTap(i),
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: workout != null 
                                        ? color.withOpacity(0.8)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _days[i],
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _savePlan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Plan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}