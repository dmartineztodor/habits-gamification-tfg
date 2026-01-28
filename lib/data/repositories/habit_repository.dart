import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habits_gamification/data/models/Habit.dart';

class HabitRepository {
  final FirebaseFirestore _firestore;

  HabitRepository(this._firestore);

  // CREATE: Añadir un nuevo hábito (a Firestore)
  Future<void> addHabit(String userId, Habit habit) async {
    try {
      // Guardamos en: users -> [ID_USUARIO] -> habits -> [ID_AUTO_GENERADO]
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .add(habit.toMap());
    } catch (e) {
      throw Exception('Error al crear hábito: $e');
    }
  }

  // READ: Obtener lista de hábitos en tiempo real
  Stream<List<Habit>> getHabits(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots() // Esto hace que se actualice solo si cambia algo en la nube
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Convertimos el documento de Firebase a nuestro objeto Habit
        return Habit.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // UPDATE: Marcar como completado o editar
  Future<void> updateHabit(String userId, Habit habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .update(habit.toMap());
    } catch (e) {
      throw Exception('Error al actualizar hábito: $e');
    }
  }

  // DELETE: Eliminar un hábito
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      throw Exception('Error al borrar hábito: $e');
    }
  }

  // Revisa todos los hábitos para resetear el día y comprobar rachas
  Future<void> checkDailyResets(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Hoy a las 00:00
    final yesterday = today.subtract(const Duration(days: 1)); // Ayer a las 00:00

    try {
      // 1. Obtenemos referencia al usuario para ver sus ESCUDOS
      final userDocRef = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDocRef.get();
      
      if (!userSnapshot.exists) return; // Seguridad

      // Leemos escudos (si no tiene campo, asumimos 0)
      int shields = userSnapshot.data()?['shields'] ?? 0;
      bool shieldUsedInThisRun = false; // Para gastar máximo 1 escudo por día globalmente

      // 2. Bajamos todos los hábitos
      final habitsSnapshot = await userDocRef.collection('habits').get();

      for (var doc in habitsSnapshot.docs) {
        final habit = Habit.fromMap(doc.data(), doc.id);
        bool needsUpdate = false;

        // Variables temporales para modificar el hábito
        bool newIsCompleted = habit.isCompleted;
        int newStreak = habit.streak;

        // Limpiamos la fecha guardada para comparar solo FECHAS (sin horas)
        final lastDate = DateTime(
          habit.lastCompletedDate.year, 
          habit.lastCompletedDate.month, 
          habit.lastCompletedDate.day
        );

        // --- CASO A: REINICIO DIARIO (Desmarcar casilla) ---
        // Si aparece completado, pero la fecha NO es de hoy...
        // Significa que fue de ayer (o antes). Hay que desmarcarlo para hoy.
        if (habit.isCompleted && lastDate.isBefore(today)) {
          newIsCompleted = false;
          needsUpdate = true;
        }

        // --- CASO B: ROMPER RACHA (Streak = 0) ---
        // Si la última vez que se completó fue ANTES de ayer...
        // Significa que ayer no hiciste nada.
        if (lastDate.isBefore(yesterday)) {
          if (habit.streak > 0) {
            // ¡MOMENTO DE USAR EL ESCUDO! 🛡️
            // Si tenemos escudos y no hemos gastado uno ya en esta revisión...
            if (shields > 0 && !shieldUsedInThisRun) {
              shields--; // Restamos escudo
              shieldUsedInThisRun = true; 
              // NO tocamos el streak, ¡se salva!
              // (Podríamos actualizar lastCompletedDate a 'ayer' para evitar chequeos futuros, 
              // pero con no poner newStreak a 0 es suficiente).
              print("¡El escudo ha salvado tu racha en: ${habit.title}! 🛡️");
            } else {
              // No hay piedad: Racha a 0 💀
              newStreak = 0;
              needsUpdate = true;
            }
          }
        }

        // 3. Si hubo cambios en el hábito, guardamos en Firebase
        if (needsUpdate) {
          final updatedHabit = Habit(
            id: habit.id,
            title: habit.title,
            isCompleted: newIsCompleted, // Nuevo estado
            lastCompletedDate: habit.lastCompletedDate, // Mantenemos la fecha original
            streak: newStreak, // Nueva racha (o 0 si murió)
            difficulty: habit.difficulty,
            steps: habit.steps,
          );
          
          await updateHabit(userId, updatedHabit);
        }
      }

      // 4. Si gastamos un escudo, actualizamos el inventario del usuario
      if (shieldUsedInThisRun) {
        await userDocRef.update({
          'shields': shields
        });
      }

    } catch (e) {
      print("Error en el auditor nocturno: $e");
    }
  }
}