class AppUser {
  final String id;
  final String email;
  final String displayName;
  final int currentLevel;
  final int currentXp;
  final int coins;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.coins = 0,
  });

  // Convertir de Map (Firebase) a Objeto Dart
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      id: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Usuario',
      currentLevel: map['currentLevel'] ?? 1,
      currentXp: map['currentXp'] ?? 0,
      coins: map['coins'] ?? 0,
    );
  }

  // Convertir de Objeto Dart a Map (para subir a Firebase)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'currentLevel': currentLevel,
      'currentXp': currentXp,
      'coins': coins,
    };
  }
}