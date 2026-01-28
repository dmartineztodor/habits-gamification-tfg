import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/Habit.dart';
import 'create_habit_screen.dart';
import 'execute_routine_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  
  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para que se ejecute justo después de pintar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        // Llamamos a la función de reinicio que acabamos de crear
        ref.read(habitRepositoryProvider).checkDailyResets(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(userHabitsProvider);
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${userAsync.value?.displayName ?? 'Jugador'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const ProfileScreen())
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.store, color: Colors.deepPurple),
            tooltip: "Tienda",
            onPressed: () {
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => const ShopScreen())
               );
            },
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

// Widget de la tarjeta (se mantiene igual, solo lo incluyo para que el código esté completo)
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
          child: Icon(habit.isCompleted ? Icons.check : Icons.fire_extinguisher, color: Colors.white),
        ),
        title: Text(
          habit.title,
          style: TextStyle(
            decoration: habit.isCompleted ? TextDecoration.lineThrough : null,
            color: habit.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
            Text(" Racha: ${habit.streak} días"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Si ya está completado hoy, avisamos y no dejamos entrar (o podrías dejar entrar solo para ver)
          if (habit.isCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("¡Ya cumpliste esta misión hoy! Vuelve mañana.")),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExecuteRoutineScreen(habit: habit),
            ),
          );
        },
      ),
    );
  }
}