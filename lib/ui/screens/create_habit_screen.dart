import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateHabitScreen extends StatefulWidget {
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _titleController = TextEditingController();
  final List<String> _steps = []; 
  final _stepController = TextEditingController();
  bool _isSaving = false; // Para mostrar cargando al guardar

  // --- FUNCIÓN PARA AÑADIR UN PASO ---
  void _addStep() {
    if (_stepController.text.trim().isNotEmpty) {
      setState(() {
        _steps.add(_stepController.text.trim());
        _stepController.clear();
      });
    }
  }

  // --- FUNCIÓN PARA GUARDAR EN FIREBASE ---
  void _saveHabit() async {
    final title = _titleController.text.trim();
    
    // 1. Validaciones básicas
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a tu rutina')),
      );
      return;
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una tarea')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 2. Guardamos en la subcolección 'habits' del usuario
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .add({
          'title': title,
          'steps': _steps, // Guardamos la lista de pasos
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        if (mounted) {
          Navigator.pop(context); // Volvemos a la Home
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Misión'),
        actions: [
          // BOTÓN GUARDAR
          TextButton(
            onPressed: _isSaving ? null : _saveHabit,
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nombre de la rutina", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ej: Entrenamiento Espartano',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 24),

            const Text("Tareas / Pasos", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // LISTA VISUAL
            Expanded(
              child: _steps.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 50, color: Colors.grey.shade300),
                        Text("Añade tareas para completar", style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.deepPurple.shade50,
                            child: Text("${index + 1}", style: const TextStyle(color: Colors.deepPurple)),
                          ),
                          title: Text(_steps[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent),
                            onPressed: () => setState(() => _steps.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
            ),

            const SizedBox(height: 10),

            // INPUT PARA AÑADIR
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: const InputDecoration(hintText: 'Ej: 10 Flexiones...'),
                    onSubmitted: (_) => _addStep(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addStep,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}