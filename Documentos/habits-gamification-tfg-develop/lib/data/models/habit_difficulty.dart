enum HabitDifficulty {
  easy,
  medium,
  hard,
  critical;

  // Lógica de XP según dificultad
  int get xpReward {
    switch (this) {
      case HabitDifficulty.easy:
        return 10; // Poco esfuerzo
      case HabitDifficulty.medium:
        return 30; // Esfuerzo normal
      case HabitDifficulty.hard:
        return 60; // Mucho esfuerzo
      case HabitDifficulty.critical:
        return 100; // Hábito clave
    }
  }

  // Lógica de monedas según dificultad
  int get coinReward {
    switch (this) {
      case HabitDifficulty.easy:
        return 2;
      case HabitDifficulty.medium:
        return 5;
      case HabitDifficulty.hard:
        return 15;
      case HabitDifficulty.critical:
        return 30;
    }
  }
  
  // Texto bonito para mostrar en pantalla (UI)
  String get label {
    switch (this) {
      case HabitDifficulty.easy:
        return 'Fácil';
      case HabitDifficulty.medium:
        return 'Medio';
      case HabitDifficulty.hard:
        return 'Difícil';
      case HabitDifficulty.critical:
        return 'Crítico';
    }
  }
}