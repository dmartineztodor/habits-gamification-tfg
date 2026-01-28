import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  // Stream para saber si el usuario está conectado en tiempo real
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener usuario actual, datos básicos de Auth
  User? get currentUser => _auth.currentUser;

  // Iniciar Sesión
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // Registrarse + Crear Perfil de Juego
  Future<void> register(String email, String password, String name) async {
    try {
      // Crear cuenta en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("No se pudo crear el usuario");

      // Crear documento en Firestore (BBDD)
      final newAppUser = AppUser(
        id: user.uid,
        email: email,
        displayName: name,
        currentLevel: 1, // Empieza nivel 1
        currentXp: 0,
        coins: 0,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newAppUser.toMap());

    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  // Cerrar Sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Escuchar los datos del jugador en tiempo real (XP, Nivel, Monedas)
  Stream<AppUser?> getUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots() // <--- Esto mantiene la conexión abierta
        .map((snapshot) {
          if (!snapshot.exists) return null;
          // Convertimos los datos crudos de Firestore a objeto AppUser
          return AppUser.fromMap(snapshot.data()!, snapshot.id);
        });
  }

  // Sumar recompensas y calcular nivel
  Future<void> addRewards(String uid, int xpEarned, int coinsEarned) async {
    final userDocRef = _firestore.collection('users').doc(uid);

    // Usamos una transacción para que sea seguro (por si ganas XP desde dos sitios a la vez)
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      int currentXp = data['currentXp'] ?? 0;
      int currentLevel = data['currentLevel'] ?? 1;
      int currentCoins = data['coins'] ?? 0;

      // 1. Sumamos lo ganado
      int newXp = currentXp + xpEarned;
      int newCoins = currentCoins + coinsEarned;
      int newLevel = currentLevel;

      // 2. Lógica de LEVEL UP (Subir de nivel)
      // Fórmula: Cada nivel cuesta (Nivel * 100) XP.
      // Ej: Nivel 1 -> 100xp. Nivel 2 -> 200xp.
      int xpToNextLevel = newLevel * 100;

      while (newXp >= xpToNextLevel) {
        newXp -= xpToNextLevel; // Restamos la XP gastada
        newLevel++;             // ¡SUBIMOS DE NIVEL!
        xpToNextLevel = newLevel * 100; // Calculamos el siguiente escalón
      }

      // 3. Guardamos los cambios
      transaction.update(userDocRef, {
        'currentXp': newXp,
        'currentLevel': newLevel,
        'coins': newCoins,
      });
    });
  }

  // Comprar un ítem (Gastar monedas)
  Future<void> purchaseItem(String uid, String itemName, int price) async {
    final userDocRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      if (!snapshot.exists) throw Exception("Usuario no encontrado");

      final data = snapshot.data()!;
      int currentCoins = data['coins'] ?? 0;
      int currentShields = data['shields'] ?? 0;

      // 1. Cobrar
      if (currentCoins < price) {
        throw Exception("No tienes suficientes monedas");
      }
      int newCoins = currentCoins - price;

      // 2. Entregar el producto (Lógica de inventario)
      Map<String, dynamic> updates = {'coins': newCoins};

      if (itemName == "Escudo Divino") {
        updates['shields'] = currentShields + 1; // damos un escudo
      } 

      // 3. Guardar cambios
      transaction.update(userDocRef, updates);
    });
  }
}