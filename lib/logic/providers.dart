import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/repositories/habit_repository.dart';
import '../data/repositories/auth_repository.dart';
import 'package:habits_gamification/data/models/Habit.dart';
import 'controllers/habit_controller.dart';
import 'controllers/auth_controller.dart';

// === SERVICIOS BASE (FIREBASE) ===
// Proveedor de Firestore (Base de datos)
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Proveedor de FirebaseAuth (autenticación)
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// === Repositorios (lógica) ===
// Proveedor del HabitRepository
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return HabitRepository(firestore);
});

// Proveedor del AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepository(auth, firestore);
});

// === STREAMS (estado en tiempo real) ===
// Dice a la app si el usuario está logueado o no
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// Controller de Autenticación (Lógica de UI)
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository);
});

// === Lógica de habitos ===
// Controller para acciones (Añadir, Borrar, Editar)
final habitControllerProvider = StateNotifierProvider<HabitController, AsyncValue<void>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return HabitController(repository: repo);
});

// Stream de datos (La lista de hábitos en tiempo real)
final userHabitsProvider = StreamProvider<List<Habit>>((ref) {
  // Obtenemos el usuario actual
  final userState = ref.watch(authStateProvider);
  final user = userState.value;

  // Si no hay usuario logueado, devolvemos lista vacía por seguridad
  if (user == null) {
    return const Stream.empty();
  }

  // Si hay usuario, pedimos sus hábitos al repositorio
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getHabits(user.uid);
});