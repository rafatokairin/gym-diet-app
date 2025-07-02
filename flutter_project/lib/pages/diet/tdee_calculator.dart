import 'package:flutter/material.dart';
import 'package:flutter_project/pages/services/tdee.dart';
import 'package:flutter_project/pages/services/auth.dart';

class TDEECalculatorPage extends StatefulWidget {
  const TDEECalculatorPage({Key? key}) : super(key: key);

  @override
  _TDEECalculatorPageState createState() => _TDEECalculatorPageState();
}

class _TDEECalculatorPageState extends State<TDEECalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final AuthService authService = AuthService();
  late UserGCDService _userGCDService;

  double? _activityFactor;
  double? _goalFactor;

  int? _tdee;
  int? _carbs;
  int? _proteins;
  int? _fats;
  int? _fibers;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _activityOptions = [
    {'label': 'Sedentary', 'value': 1.2},
    {'label': 'Light', 'value': 1.375},
    {'label': 'Moderate', 'value': 1.55},
    {'label': 'Active', 'value': 1.725},
    {'label': 'Very Active', 'value': 1.9},
  ];

  final List<Map<String, dynamic>> _goalOptions = [
    {'label': 'Cutting', 'value': 0.6},
    {'label': 'Maintenance', 'value': 1.0},
    {'label': 'Bulking', 'value': 1.5},
  ];

  @override
  void initState() {
    super.initState();
    _userGCDService = UserGCDService(authService, context);
    _loadExistingData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final gcdData = await _userGCDService.getUserGCD();
      if (gcdData.isNotEmpty) {
        setState(() {
          _tdee = gcdData['gcd']?.toInt();
          _carbs = gcdData['carboidratos_gcd']?.toInt();
          _proteins = gcdData['proteinas_gcd']?.toInt();
          _fats = gcdData['gorduras_gcd']?.toInt();
          _fibers = gcdData['fibras_gcd']?.toInt();
        });
      }
    } catch (e) {
      // Ignora erros de carga (usuário pode não ter dados ainda)
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateAndSaveTDEE() async {
    if (!_formKey.currentState!.validate() ||
        _activityFactor == null ||
        _goalFactor == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final double weight = double.parse(_weightController.text);
      final double height = double.parse(_heightController.text);
      final double age = double.parse(_ageController.text);

      // Cálculo do TDEE
      final double bmr = 66.47 + (13.75 * weight) + (5 * height) - (6.8 * age);
      final int tdee = (bmr * _activityFactor!).round();

      final int proteins = (_activityFactor! * weight).round();
      final int fats = (_goalFactor! * weight).round();
      final int carbs = ((tdee - (proteins * 4) - (fats * 9)) / 4).round();
      final int fibers = ((tdee / 1000) * 14).round();

      // Dados para enviar ao backend
      final gcdData = {
        'carboidratos_gcd': carbs,
        'proteinas_gcd': proteins,
        'fibras_gcd': fibers,
        'gorduras_gcd': fats,
        'gcd': tdee,
      };

      // Tentar atualizar primeiro, se falhar, adicionar novo
      try {
        await _userGCDService.updateUserGCD(gcdData);
      } catch (e) {
        await _userGCDService.addUserGCD(gcdData);
      }

      setState(() {
        _tdee = tdee;
        _proteins = proteins;
        _fats = fats;
        _carbs = carbs;
        _fibers = fibers;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save TDEE data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTDEE() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userGCDService.deleteUserGCD();
      
      if (!mounted) return;
      
      setState(() {
        _tdee = null;
        _carbs = null;
        _proteins = null;
        _fats = null;
        _fibers = null;
        _weightController.clear();
        _heightController.clear();
        _ageController.clear();
        _activityFactor = null;
        _goalFactor = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to delete TDEE data: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMacroRow(String label, int? grams, int kcalPerGram, Color color) {
    final String detail = grams != null
        ? kcalPerGram > 0
            ? '$grams g (${grams * kcalPerGram} kcal)'
            : '$grams g'
        : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          Text(detail),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TDEE Calculator'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter weight' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter height' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age (years)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Enter age' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<double>(
                          value: _activityFactor,
                          decoration: const InputDecoration(
                            labelText: 'Activity Factor',
                            border: OutlineInputBorder(),
                          ),
                          items: _activityOptions.map((option) {
                            return DropdownMenuItem<double>(
                              value: option['value'],
                              child: Text(option['label']),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _activityFactor = v),
                          validator: (v) => v == null ? 'Select factor' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<double>(
                          value: _goalFactor,
                          decoration: const InputDecoration(
                            labelText: 'Goal Factor',
                            border: OutlineInputBorder(),
                          ),
                          items: _goalOptions.map((option) {
                            return DropdownMenuItem<double>(
                              value: option['value'],
                              child: Text(option['label']),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _goalFactor = v),
                          validator: (v) => v == null ? 'Select goal' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _calculateAndSaveTDEE,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Calculate',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_tdee != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete TDEE Data'),
                            content: const Text(
                                'Are you sure you want to delete your TDEE data?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteTDEE();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Delete TDEE Data',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              '${_tdee} kcal/day',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMacroRow('Proteins', _proteins, 4, Colors.orange),
                          _buildMacroRow('Fats', _fats, 9, Colors.red),
                          _buildMacroRow('Carbs', _carbs, 4, Colors.green),
                          _buildMacroRow('Fibers', _fibers, 0, Colors.brown),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}