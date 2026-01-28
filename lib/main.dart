import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'logic/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado de autenticación
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Habits Gamification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Lógica de enrutamiento automática
      home: authState.when(
        data: (user) {
          if (user != null) return const HomeScreen(); // Usuario logueado
          return const LoginScreen(); // Usuario no logueado
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}