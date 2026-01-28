import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/Habit.dart';

class ExecuteRoutineScreen extends ConsumerStatefulWidget {
  final Habit habit; // Ahora recibimos el hábito completo (con ID), no solo el título

  const ExecuteRoutineScreen({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<ExecuteRoutineScreen> createState() => _ExecuteRoutineScreenState();
}

class _ExecuteRoutineScreenState extends ConsumerState<ExecuteRoutineScreen> {
  // Simulamos unos pasos fijos porque el modelo Habit aún no tiene lista de pasos
  // TODO: En el futuro, esto vendrá de widget.habit.steps
  final List<String> _fakeSteps = [
    "Prepárate mentalmente",
    "¡Hazlo sin pensar!",
    "Sonríe al terminar"
  ];
  
  late List<bool> _checkedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkedStatus = List<bool>.filled(_fakeSteps.length, false);
  }

  double get _progress {
    if (_fakeSteps.isEmpty) return 0;
    int completed = _checkedStatus.where((c) => c).length;
    return completed / _fakeSteps.length;
  }

  // --- LÓGICA PARA COMPLETAR LA MISIÓN ---
  void _finishRoutine() async {
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // 1. Creamos una copia del hábito actualizado
        final updatedHabit = Habit(
          id: widget.habit.id,
          title: widget.habit.title,
          difficulty: widget.habit.difficulty,
          // CAMBIOS CLAVE:
          isCompleted: true, // ¡Misión cumplida!
          lastCompletedDate: DateTime.now(), // Fecha de hoy
          streak: widget.habit.streak + 1, // Aumentamos racha
        );

        // 2. Guardamos en Firebase usando tu Controller
        await ref.read(habitControllerProvider.notifier).updateHabit(user.uid, updatedHabit);

        // 3. Feedback visual y salir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Misión Completada! +${widget.habit.xp} XP 🌟'),
              backgroundColor: Colors.amber,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Volver al Home
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.title)),
      body: Column(
        children: [
          // BARRA DE PROGRESO
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            color: _progress == 1.0 ? Colors.green : Colors.deepPurple,
            minHeight: 10,
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fakeSteps.length,
              itemBuilder: (context, index) {
                return Card(
                  child: CheckboxListTile(
                    title: Text(
                      _fakeSteps[index],
                      style: TextStyle(
                        decoration: _checkedStatus[index] ? TextDecoration.lineThrough : null,
                        color: _checkedStatus[index] ? Colors.grey : Colors.black,
                      ),
                    ),
                    value: _checkedStatus[index],
                    onChanged: (bool? value) {
                      setState(() {
                        _checkedStatus[index] = value ?? false;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // BOTÓN DE TERMINAR
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                // Solo se activa si está al 100% y no está guardando
                onPressed: (_progress == 1.0 && !_isSaving) ? _finishRoutine : null,
                icon: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle),
                label: Text(_isSaving ? "GUARDANDO..." : "RECLAMAR RECOMPENSA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}