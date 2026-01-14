import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart'; // Configurar Firebase
// import 'firebase_options.dart'; // Esto se generará después

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Daniel -> Inicializar Firebase aquí la próxima vez
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habits Gamification',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Hola Rubén, empieza a trabajar en ui/screens'),
        ),
      ),
    );
  }
}