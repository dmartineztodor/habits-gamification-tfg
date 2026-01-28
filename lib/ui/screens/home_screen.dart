import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/Habit.dart';
import 'create_habit_screen.dart';
import 'execute_routine_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchamos la lista de hábitos en tiempo real
    final habitsAsync = ref.watch(userHabitsProvider);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${userAsync.value?.displayName ?? 'Jugador'}'),
        actions: [
          // NUEVO: Botón de Perfil
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               // Navegar al perfil
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const ProfileScreen())
               );
            },
          ),
          // Botón de salir (ya lo tenías)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Text("No tienes misiones activas. \n¡Crea una nueva! 🚀"),
            );
          }
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return HabitCard(habit: habit);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateHabitScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HabitCard extends StatelessWidget {
  final Habit habit;
  const HabitCard({required this.habit, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: habit.isCompleted ? Colors.green : Colors.grey,
          child: Icon(habit.isCompleted ? Icons.check : Icons.fitness_center, color: Colors.white),
        ),
        title: Text(habit.title),
        subtitle: Text("Recompensa: ${habit.xp} XP"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExecuteRoutineScreen(
                habit: habit, // Pasamos el objeto entero
              ),
            ),
          );
        },
      ),
    );
  }
}