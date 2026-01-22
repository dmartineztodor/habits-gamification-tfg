import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'firebase_options.dart'; 

// TUS IMPORTS DE PANTALLAS
import 'package:habits_gamification/ui/screens/create_habit_screen.dart';
import 'package:habits_gamification/ui/screens/login_screen.dart';
import 'package:habits_gamification/ui/screens/nickname_screen.dart';
import 'package:habits_gamification/services/auth_service.dart';
import 'package:habits_gamification/ui/screens/execute_routine_screen.dart'; // <--- Importante para que funcione el onTap

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits Gamification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
         filled: true,
         fillColor: Colors.grey.shade100,
         border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
        ),
       ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen(); 
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, trace) => Scaffold(
        body: Center(child: Text('Error de autenticación: $e')),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits RPG'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            
            // -------------------------------------------------------------
            // PARTE 1: CABECERA CON FOTO Y NICKNAME
            // -------------------------------------------------------------
            if (user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator(); 
                  }
                  
                  final data = snapshot.data?.data() as Map<String, dynamic>?;

                  // LÓGICA DEL PORTERO (Redirección si falta nickname)
                  if (data != null && !data.containsKey('nickname')) {
                    Future.microtask(() {
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => const NicknameScreen())
                        );
                      }
                    });
                    return const SizedBox(); 
                  }

                  final nickname = data?['nickname'] ?? user.displayName ?? 'Guerrero';

                  return Row(
                    children: [
                      if (user.photoURL != null)
                        CircleAvatar(backgroundImage: NetworkImage(user.photoURL!), radius: 30)
                      else
                        const Icon(Icons.account_circle, size: 60, color: Colors.deepPurple),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hola, $nickname', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          const Text('Nivel 1 • Principiante', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 30),
            const Text("MIS MISIONES", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            // -------------------------------------------------------------
            // PARTE 2: LA LISTA DE RUTINAS CON NAVEGACIÓN
            // -------------------------------------------------------------
            if (user != null)
              Expanded( 
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('habits') 
                      .orderBy('createdAt', descending: true) 
                      .snapshots(),
                  builder: (context, snapshot) {
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checklist_rtl, size: 60, color: Colors.grey.shade300),
                            const Text("No tienes rutinas activas", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    // PINTAR LA LISTA DE TARJETAS
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data!.docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final steps = List<String>.from(data['steps'] ?? []);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              data['title'] ?? 'Rutina sin nombre',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Text(
                              "${steps.length} tareas por completar",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 40),
                            
                            // AQUÍ ESTÁ EL CAMBIO CLAVE: NAVEGACIÓN
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ExecuteRoutineScreen(
                                    title: data['title'] ?? 'Misión',
                                    steps: steps, // Pasamos la lista de pasos a la otra pantalla
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
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