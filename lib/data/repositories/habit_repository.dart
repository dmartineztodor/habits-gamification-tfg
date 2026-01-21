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
}