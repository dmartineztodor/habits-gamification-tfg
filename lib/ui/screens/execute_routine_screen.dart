import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/Habit.dart';

class ExecuteRoutineScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const ExecuteRoutineScreen({
    super.key,
    required this.habit,
  });

  @override
  ConsumerState<ExecuteRoutineScreen> createState() => _ExecuteRoutineScreenState();
}

class _ExecuteRoutineScreenState extends ConsumerState<ExecuteRoutineScreen> {
  late List<bool> _checkedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // AHORA USAMOS LOS PASOS REALES (widget.habit.steps)
    // Si no tiene pasos, creamos una lista vacía
    if (widget.habit.steps.isNotEmpty) {
      _checkedStatus = List<bool>.filled(widget.habit.steps.length, false);
    } else {
      _checkedStatus = [];
    }
  }

  double get _progress {
    if (widget.habit.steps.isEmpty) {
      // Si no hay pasos, el progreso es 0 o 1 dependiendo de si le das a terminar
      // Pero para simplificar, si no hay pasos, asumimos que es una tarea simple (tipo checkbox único)
      return 0.0; 
    }
    int completed = _checkedStatus.where((c) => c).length;
    return completed / widget.habit.steps.length;
  }

  void _finishRoutine() async {
    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // 1. Actualizar el HÁBITO (marcarlo completado)
        final updatedHabit = Habit(
          id: widget.habit.id,
          title: widget.habit.title,
          difficulty: widget.habit.difficulty,
          isCompleted: true,
          lastCompletedDate: DateTime.now(),
          streak: widget.habit.streak + 1,
          steps: widget.habit.steps,
        );

        // Llamamos al Controller de Hábitos
        await ref.read(habitControllerProvider.notifier).updateHabit(user.uid, updatedHabit);

        // 2. NUEVO: Dar RECOMPENSAS al Usuario (XP y Monedas)
        // Usamos la dificultad del hábito para saber cuánto pagar
        await ref.read(authRepositoryProvider).addRewards(
          user.uid, 
          widget.habit.xp,    // XP según dificultad (Easy=10, Hard=60...)
          widget.habit.coins  // Monedas según dificultad
        );

        if (mounted) {
          // Mensaje de victoria
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡Misión Completada! +${widget.habit.xp} XP | +${widget.habit.coins} 💰'),
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
    // Si la misión NO tiene pasos, mostramos un diseño simplificado
    bool isSimpleTask = widget.habit.steps.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.habit.title)),
      body: Column(
        children: [
          // Barra de progreso (Solo si hay pasos)
          if (!isSimpleTask)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              color: _progress == 1.0 ? Colors.green : Colors.deepPurple,
              minHeight: 10,
            ),
          
          Expanded(
            child: isSimpleTask
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        "Misión Simple",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text("¡Completa la tarea y reclama tu premio!"),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.habit.steps.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: CheckboxListTile(
                        title: Text(
                          widget.habit.steps[index], // <--- Texto real de la BBDD
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
                // Si es tarea simple, siempre activo. Si tiene pasos, solo al 100%
                onPressed: (isSimpleTask || _progress == 1.0) && !_isSaving 
                    ? _finishRoutine 
                    : null,
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