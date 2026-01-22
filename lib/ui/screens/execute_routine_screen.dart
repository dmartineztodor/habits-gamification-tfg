import 'package:flutter/material.dart';

class ExecuteRoutineScreen extends StatefulWidget {
  final String title;
  final List<String> steps;

  const ExecuteRoutineScreen({
    super.key,
    required this.title,
    required this.steps,
  });

  @override
  State<ExecuteRoutineScreen> createState() => _ExecuteRoutineScreenState();
}

class _ExecuteRoutineScreenState extends State<ExecuteRoutineScreen> {
  // Lista para saber qué casillas están marcadas
  late List<bool> _checkedStatus;

  @override
  void initState() {
    super.initState();
    // Al principio, todas las casillas están desmarcadas (false)
    _checkedStatus = List<bool>.filled(widget.steps.length, false);
  }

  // Calculamos el progreso (0.0 a 1.0) para la barra
  double get _progress {
    if (widget.steps.isEmpty) return 0;
    int completed = _checkedStatus.where((c) => c).length;
    return completed / widget.steps.length;
  }

  void _finishRoutine() {
    // Aquí más adelante guardaremos que has terminado la rutina en Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Misión Completada! +10 EXP'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context); // Volver a la home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Column(
        children: [
          // 1. BARRA DE PROGRESO
          LinearProgressIndicator(
            value: _progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            color: Colors.green,
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${(_progress * 100).toInt()}% Completado",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // 2. LISTA DE TAREAS (Checkboxes)
          Expanded(
            child: ListView.builder(
              itemCount: widget.steps.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  // Si está marcada, la ponemos un poco gris
                  color: _checkedStatus[index] ? Colors.green.shade50 : Colors.white,
                  child: CheckboxListTile(
                    title: Text(
                      widget.steps[index],
                      style: TextStyle(
                        // Tachamos el texto si está completado
                        decoration: _checkedStatus[index] ? TextDecoration.lineThrough : null,
                        color: _checkedStatus[index] ? Colors.grey : Colors.black,
                      ),
                    ),
                    value: _checkedStatus[index],
                    activeColor: Colors.green,
                    onChanged: (bool? value) {
                      setState(() {
                        _checkedStatus[index] = value ?? false;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 3. BOTÓN TERMINAR
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _progress == 1.0 ? _finishRoutine : null, // Solo se activa si está al 100%
                icon: const Icon(Icons.check_circle),
                label: const Text("TERMINAR MISIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}