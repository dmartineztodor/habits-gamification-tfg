import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/habit_repository.dart';
import 'package:habits_gamification/data/models/Habit.dart';


// Gestiona el estado de las acciones añadir, borrar, editar)
// AsyncValue<void> nos sirve para saber si está cargando o si hubo algún error
class HabitController extends StateNotifier<AsyncValue<void>> {
  final HabitRepository _repository;

  HabitController({required HabitRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(null));

  // Crear Hábito
  Future<void> addHabit(String userId, Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addHabit(userId, habit));
  }

  // Editar Hábito
  Future<void> updateHabit(String userId, Habit habit) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateHabit(userId, habit));
  }

  // Eliminar Hábito
  Future<void> deleteHabit(String userId, String habitId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteHabit(userId, habitId));
  }
}