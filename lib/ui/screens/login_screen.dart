import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits_gamification/services/auth_service.dart';
import 'package:habits_gamification/ui/screens/register_screen.dart';
import 'package:habits_gamification/ui/screens/nickname_screen.dart'; // Para NicknameScreen
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Lógica para Login con Email (se mantiene igual)
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authServiceProvider).loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        // Si el login es exitoso, el StreamProvider de main.dart debería redirigir automáticamente,
        // pero si quieres forzar la comprobación de nickname aquí también, podrías hacerlo.
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // AQUI ES DONDE HEMOS ARREGLADO LA LÓGICA
  void _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. Obtenemos el servicio
      final authService = ref.read(authServiceProvider);
      
      // 2. Ejecutamos el login
      final user = await authService.signInWithGoogle();

      if (user != null) {
        // 3. Comprobamos si tiene Nickname
        bool hasNick = await authService.userHasNickname(user.uid);

        if (mounted) {
          if (hasNick) {
            // CASO A: Ya tiene nickname -> Vamos a la Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // CASO B: No tiene nickname -> Vamos a crearlo
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NicknameScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error con Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO DEGRADADO
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF654ea3), Color(0xFFeaafc8)], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // 2. TARJETA CENTRAL
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono Superior
                        const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
                        const SizedBox(height: 20),
                        
                        Text(
                          'Level Up Your Life',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // INPUT EMAIL
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color.fromARGB(255, 174, 145, 224), width: 2),
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Falta el email' : null,
                        ),
                        const SizedBox(height: 16),

                        // INPUT PASSWORD
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                            ),
                          ),
                          validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                        ),
                        const SizedBox(height: 24),

                        // BOTÓN LOGIN
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              backgroundColor: Colors.deepOrangeAccent,
                              foregroundColor: Colors.blueAccent, 
                            ),
                            child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                              : const Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // BOTÓN GOOGLE
                        OutlinedButton.icon(
                           // AQUI LLAMAMOS A LA FUNCIÓN CORREGIDA
                           onPressed: _isLoading ? null : _googleLogin,
                           icon: const Icon(Icons.g_mobiledata, size: 28),
                           label: const Text('Google'),
                           style: OutlinedButton.styleFrom(
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                           ),
                        ),
                        
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text('Crear cuenta nueva'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}