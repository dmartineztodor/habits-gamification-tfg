import 'habit_difficulty.dart';

class Habit {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime lastCompletedDate;
  final int streak;
  final HabitDifficulty difficulty;
  final List<String> steps;

  Habit({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.lastCompletedDate,
    this.streak = 0,
    this.difficulty = HabitDifficulty.easy,
    this.steps = const [],
  });

  int get xp => difficulty.xpReward;
  int get coins => difficulty.coinReward;

  // Importar de Firebase
  factory Habit.fromMap(Map<String, dynamic> map, String documentId) {
    return Habit(
      id: documentId,
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      lastCompletedDate: DateTime.parse(map['lastCompletedDate']),
      streak: map['streak'] ?? 0,
      difficulty: HabitDifficulty.values.firstWhere(
        (e) => e.name == (map['difficulty'] ?? 'easy'),
        orElse: () => HabitDifficulty.easy,
      ),
      // Mapeamos la lista de pasos. Si no existe, usamos lista vacía.
      steps: List<String>.from(map['steps'] ?? []), // <--- MAGIA AQUÍ
    );
  }

  // Exportar a Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'lastCompletedDate': lastCompletedDate.toIso8601String(),
      'streak': streak,
      'difficulty': difficulty.name,
      'steps': steps,
    };
  }
}