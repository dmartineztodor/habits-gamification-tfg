import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Obtenemos el usuario actual logueado
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // 2. Guardamos el nickname en Firestore dentro de la colección 'users'
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nickname': nickname,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // merge: true para no borrar otros datos si existieran

        // 3. Vamos a la Home
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()), // Cambia HomeScreen por el nombre real de tu clase principal
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videogame_asset, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                "¿Cómo te llamamos?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Elige tu nombre de jugador para empezar la aventura.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: "Tu Nickname",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNickname,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("COMENZAR"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}