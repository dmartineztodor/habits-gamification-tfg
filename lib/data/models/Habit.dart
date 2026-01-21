import 'habit_difficulty.dart'; // Importamos la clase que gestiona la dificultad del hábito

class Habit {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime lastCompletedDate;
  final int streak;
  final HabitDifficulty difficulty;

  Habit({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.lastCompletedDate,
    this.streak = 0,
    this.difficulty = HabitDifficulty.easy, // Valor por defecto
  });

  int get xp => difficulty.xpReward;
  int get coins => difficulty.coinReward;

  // Función que importa los datos de la base de datos firebase
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
    );
  }

  // Función para enviar datos de la aplicación a nuestra base de datos firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'lastCompletedDate': lastCompletedDate.toIso8601String(),
      'streak': streak,
      'difficulty': difficulty.name,
    };
  }
}