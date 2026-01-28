import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../data/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Jugador"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
               // Aquí podrías poner ajustes en el futuro
            },
          )
        ],
      ),
      body: userStats.when(
        data: (user) {
          if (user == null) return const Center(child: Text("Error al cargar perfil"));
          return _buildBody(context, user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppUser user) {
    // Lógica simple de nivel: Cada nivel requiere (Nivel * 100) XP
    // Ejemplo: Nivel 1 necesita 100 XP. Nivel 2 necesita 200 XP.
    int nextLevelXp = user.currentLevel * 100;
    double progress = user.currentXp / nextLevelXp;
    // Nos aseguramos de que la barra no se pase de 1.0 (100%)
    if (progress > 1.0) progress = 1.0; 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. AVATAR Y NOMBRE
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user.email,
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 30),

          // 2. TARJETA DE ESTADÍSTICAS PRINCIPALES
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem("NIVEL", "${user.currentLevel}", Colors.blue),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _statItem("MONEDAS", "${user.coins} 💰", Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. BARRA DE EXPERIENCIA (XP)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Experiencia (XP)", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 20,
              backgroundColor: Colors.grey.shade200,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${user.currentXp} XP"),
              Text("$nextLevelXp XP (Siguiente Nivel)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            color: color
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: Colors.grey
          ),
        ),
      ],
    );
  }
}