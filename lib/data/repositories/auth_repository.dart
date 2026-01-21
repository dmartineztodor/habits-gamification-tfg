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
}