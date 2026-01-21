import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits_gamification/services/auth_service.dart';
import 'package:habits_gamification/ui/screens/register_screen.dart';

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

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ref.read(authServiceProvider).loginWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
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

  void _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
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

  // AQUÍ ESTÁ EL DISEÑO DEFINITIVO (Fusionado)
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

                        // INPUT EMAIL (Con tu personalización del icono morado)
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            // Aquí está tu icono morado:
                            prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            // Borde redondeado y bonito
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            // Borde cuando pulsas (Morado)
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

                        // BOTÓN LOGIN (Con tus colores Naranja/Azul)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              // Forma redondeada
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              // TUS COLORES PERSONALIZADOS:
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