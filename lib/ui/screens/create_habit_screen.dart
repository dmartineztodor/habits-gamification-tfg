import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/Habit.dart';
import '../../data/models/habit_difficulty.dart';

class CreateHabitScreen extends ConsumerStatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  ConsumerState<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends ConsumerState<CreateHabitScreen> {
  final _titleController = TextEditingController();
  final _stepController = TextEditingController();
  
  // Estado local
  final List<String> _steps = []; 
  bool _isSaving = false;
  HabitDifficulty _selectedDifficulty = HabitDifficulty.medium; // Dificultad por defecto

  @override
  void dispose() {
    _titleController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PARA AÑADIR UN PASO (Solo visual por ahora) ---
  void _addStep() {
    if (_stepController.text.trim().isNotEmpty) {
      setState(() {
        _steps.add(_stepController.text.trim());
        _stepController.clear();
      });
    }
  }

  // --- FUNCIÓN PARA GUARDAR EN FIREBASE (CONECTADA) ---
  void _saveHabit() async {
    final title = _titleController.text.trim();
    
    // 1. Validaciones básicas de formulario
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ponle un nombre a tu misión')),
      );
      return;
    }

    // 2. Bloqueamos el botón y mostramos carga
    setState(() => _isSaving = true);

    try {
      // 3. Obtenemos el usuario logueado desde Riverpod
      final user = ref.read(authStateProvider).value;
      
      if (user != null) {
        // 4. Creamos el objeto Habit
        final newHabit = Habit(
          id: '',
          title: title,
          isCompleted: false,
          lastCompletedDate: DateTime(2000),
          difficulty: _selectedDifficulty,
          steps: _steps, // <--- ¡AQUÍ ESTÁ! Ya no ignoramos la lista _steps
        );

        // 5. ¡ENVIAMOS A FIREBASE!
        await ref.read(habitControllerProvider.notifier).addHabit(user.uid, newHabit);
        
        // 6. Si todo va bien, cerramos la pantalla
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Hábito creado! 🚀'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); 
        }
      } else {
        throw Exception("Usuario no identificado");
      }
    } catch (e) {
      // Manejo de errores
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // Desbloqueamos el botón
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Misión'),
        actions: [
          // Botón de Guardar en la barra superior
          IconButton(
            onPressed: _isSaving ? null : _saveHabit,
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple))
              : const Icon(Icons.check, color: Colors.deepPurple, size: 30),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TÍTULO
            const Text("Nombre de la Misión", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Ej: Beber 2L de agua',
                border: UnderlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 20),

            // 2. SELECTOR DE DIFICULTAD (NUEVO)
            const Text("Dificultad (Recompensa)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HabitDifficulty>(
                  value: _selectedDifficulty,
                  isExpanded: true,
                  items: HabitDifficulty.values.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Row(
                        children: [
                          // Icono o color según dificultad
                          Icon(Icons.circle, size: 12, color: _getDifficultyColor(difficulty)),
                          const SizedBox(width: 10),
                          Text("${difficulty.label} (+${difficulty.xpReward} XP)"),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedDifficulty = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. PASOS / SUBTAREAS (Visual por ahora)
            const Text("Pasos (Opcional)", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: _steps.isEmpty
                  ? const Center(
                      child: Text("Sin pasos añadidos", style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.shade50,
                              child: Text("${index + 1}", style: const TextStyle(color: Colors.deepPurple)),
                            ),
                            title: Text(_steps[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () => setState(() => _steps.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // INPUT PARA AÑADIR PASOS
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: const InputDecoration(hintText: 'Ej: 10 Flexiones...'),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addStep,
                )
              ],
            ),
            // Espacio extra para que el teclado no tape el input
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 30),
          ],
        ),
      ),
    );
  }

  // Helper para colores
  Color _getDifficultyColor(HabitDifficulty diff) {
    switch (diff) {
      case HabitDifficulty.easy: return Colors.green;
      case HabitDifficulty.medium: return Colors.orange;
      case HabitDifficulty.hard: return Colors.red;
      case HabitDifficulty.critical: return Colors.purple;
    }
  }
}