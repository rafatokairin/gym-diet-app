import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/workout.dart';
import 'package:flutter_project/pages/services/auth.dart';

// List of muscle groups in logical workout order
class WorkoutConstants {
  static const List<String> muscleGroups = [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'abs',
    'glutes',
    'calves',
    'full_body',
    'cardio',
    'mobility',
    'other'
  ];
}
// Function to format muscle group name for display
String formatMuscleGroup(String group) {
  if (group.isEmpty) return group;
  
  return group
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty 
          ? word[0].toUpperCase() + word.substring(1) 
          : '')
      .join(' ');
}

class WorkoutSplitsPage extends StatefulWidget {
  const WorkoutSplitsPage({super.key});

  @override
  State<WorkoutSplitsPage> createState() => _WorkoutSplitsPageState();
}

class _WorkoutSplitsPageState extends State<WorkoutSplitsPage> {
  final List<String> splits = ['A', 'B', 'C', 'D', 'E'];
  int selectedSplitIndex = 0;

  final AuthService authService = AuthService();
  late WorkoutService workoutService;

  Map<String, List<Map<String, dynamic>>> exercisesBySplit = {
    'A': [],
    'B': [],
    'C': [],
    'D': [],
    'E': [],
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    workoutService = WorkoutService(authService, context);

    // Definir o split padrão como A (índice 0)
    selectedSplitIndex = 0;
    
    _loadExercises();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar se recebemos um argumento com o split a ser exibido
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is String) {
      final splitIndex = splits.indexOf(routeArgs);
      if (splitIndex != -1) {
        selectedSplitIndex = splitIndex;
      }
    }
  }

  Future<void> _loadExercises() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final Map<String, List<Map<String, dynamic>>> updatedExercises = {};
      
      for (final split in splits) {
        final exercises = await workoutService.getExercises(split);
        updatedExercises[split] = exercises;
      }

      if (mounted) {
        setState(() {
          exercisesBySplit = updatedExercises;
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

  Future<void> _deleteExercise(int id) async {
    try {
      final split = splits[selectedSplitIndex];
      
      // Update local state first for immediate response
      setState(() {
        exercisesBySplit[split] = exercisesBySplit[split]!.where((exercise) => exercise['id'] != id).toList();
      });
      
      // Then call API
      await workoutService.deleteExercise(split, id);
      
      // Reload data to ensure sync with backend
      await _loadExercises();
    } catch (e) {
      print("Error deleting exercise: $e");
      // If error, reload to restore state
      await _loadExercises();
    }
  }

  Future<void> _editExercise(int id, Map<String, dynamic> updatedExercise) async {
    try {
      final split = splits[selectedSplitIndex];
      
      // Update locally first
      setState(() {
        exercisesBySplit[split] = exercisesBySplit[split]!.map((exercise) {
          return exercise['id'] == id ? {...exercise, ...updatedExercise} : exercise;
        }).toList();
      });
      
      // Then sync with backend
      await workoutService.updateExercise(split, id, updatedExercise);
      await _loadExercises();
    } catch (e) {
      print("Error editing exercise: $e");
      await _loadExercises();
    }
  }

  Future<void> _addExercise(Map<String, dynamic> newExercise) async {
    try {
      final split = splits[selectedSplitIndex];
      
      // Add locally first (with temporary ID)
      setState(() {
        exercisesBySplit[split] = [...exercisesBySplit[split]!, {...newExercise, 'id': 'temp_${DateTime.now().millisecondsSinceEpoch}'}];
      });
      
      // Then sync with backend
      await workoutService.addExercise(split, newExercise);
      await _loadExercises();
    } catch (e) {
      print("Error adding exercise: $e");
      await _loadExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = exercisesBySplit[splits[selectedSplitIndex]] ?? [];

    // Group exercises by muscle group in defined order
    final Map<String, List<Map<String, dynamic>>> groupedExercises = {};
    // Initialize with all muscle groups in order
    for (var group in WorkoutConstants.muscleGroups) {
      groupedExercises[group] = [];
    }

    // Add exercises to their respective groups
    for (var ex in exercises) {
      final group = ex['grupo_muscular'] ?? 'other';
      if (groupedExercises.containsKey(group)) {
        groupedExercises[group]!.add(ex);
      } else {
        groupedExercises['other']!.add(ex);
      }
    }

    // Remove empty muscle groups
    groupedExercises.removeWhere((key, value) => value.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Splits'),
      ),
      body: Column(
        children: [
          // Split selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: List.generate(splits.length, (index) {
                final isSelected = selectedSplitIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedSplitIndex = index;
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
                          splits[index],
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
                : (exercises.isEmpty
                    ? const Center(child: Text('No exercises added.'))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          // Show exercise groups in logical order
                          ...WorkoutConstants.muscleGroups.where((group) => groupedExercises.containsKey(group)).map((group) {
                            final groupExercises = groupedExercises[group]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    formatMuscleGroup(group),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Replace the existing exercise Card widget in the ListView with this:
                                ...groupExercises.map((exercise) {
                                  return InkWell(
                                    onTap: () {
                                      _showEditDialog(context, exercise);
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
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
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

  void _showEditDialog(BuildContext context, Map<String, dynamic> exercise) {
    String selectedMuscleGroup = exercise['grupo_muscular'] ?? '';
    final exerciseController = TextEditingController(text: exercise['nome']);
    final setsController = TextEditingController(text: exercise['series'].toString());
    final repsController = TextEditingController(text: exercise['repeticoes'].toString());
    final weightController = TextEditingController(text: exercise['peso'].toString());
    final restTimeController = TextEditingController(text: exercise['tempo'].toString());
    final notesController = TextEditingController(text: exercise['anotacao']);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
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
                          'Edit Exercise',
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
                            value: selectedMuscleGroup.isNotEmpty ? selectedMuscleGroup : null,
                            decoration: const InputDecoration(labelText: 'Muscle Group'),
                            items: WorkoutConstants.muscleGroups.map((group) {
                              return DropdownMenuItem<String>(
                                value: group,
                                child: Text(formatMuscleGroup(group)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedMuscleGroup = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a muscle group';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: exerciseController,
                            decoration: const InputDecoration(labelText: 'Exercise Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an exercise name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: setsController,
                                  decoration: const InputDecoration(labelText: 'Sets'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: repsController,
                                  decoration: const InputDecoration(labelText: 'Reps'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: weightController,
                            decoration: const InputDecoration(labelText: 'Weight (kg)'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: restTimeController,
                            decoration: const InputDecoration(labelText: 'Rest Time (min)'),
                            keyboardType: TextInputType.number,
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
                            _deleteExercise(exercise['id']);
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final updatedExercise = {
                                'grupo_muscular': selectedMuscleGroup,
                                'nome': exerciseController.text,
                                'series': int.tryParse(setsController.text) ?? 0,
                                'repeticoes': int.tryParse(repsController.text) ?? 0,
                                'peso': int.tryParse(weightController.text) ?? 0,
                                'tempo': int.tryParse(restTimeController.text) ?? 0,
                                'anotacao': notesController.text,
                              };
                              _editExercise(exercise['id'], updatedExercise);
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
  }

  void _showAddDialog(BuildContext context) {
    String selectedMuscleGroup = '';
    final exerciseController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final restTimeController = TextEditingController();
    final notesController = TextEditingController();
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
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
                          'Add Exercise',
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
                            value: selectedMuscleGroup.isNotEmpty ? selectedMuscleGroup : null,
                            decoration: const InputDecoration(labelText: 'Muscle Group'),
                            items: WorkoutConstants.muscleGroups.map((group) {
                              return DropdownMenuItem<String>(
                                value: group,
                                child: Text(formatMuscleGroup(group)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedMuscleGroup = value;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a muscle group';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: exerciseController,
                            decoration: const InputDecoration(labelText: 'Exercise Name'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an exercise name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: setsController,
                                  decoration: const InputDecoration(labelText: 'Sets'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: repsController,
                                  decoration: const InputDecoration(labelText: 'Reps'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: weightController,
                            decoration: const InputDecoration(labelText: 'Weight (kg)'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: restTimeController,
                            decoration: const InputDecoration(labelText: 'Rest Time (min)'),
                            keyboardType: TextInputType.number,
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
                              final newExercise = {
                                'grupo_muscular': selectedMuscleGroup,
                                'nome': exerciseController.text,
                                'series': int.tryParse(setsController.text) ?? 0,
                                'repeticoes': int.tryParse(repsController.text) ?? 0,
                                'peso': int.tryParse(weightController.text) ?? 0,
                                'tempo': int.tryParse(restTimeController.text) ?? 0,
                                'anotacao': notesController.text,
                              };
                              _addExercise(newExercise);
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
  }
}