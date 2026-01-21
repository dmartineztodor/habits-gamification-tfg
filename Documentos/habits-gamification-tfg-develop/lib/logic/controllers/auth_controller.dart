import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

// Este Controller maneja el estado de la autenticación (Cargando, Error, Éxito)
// StateNotifier<AsyncValue<void>> significa: "Gestiono una tarea asíncrona que no devuelve datos, solo éxito o fallo"
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AsyncValue.data(null)); // Estado inicial: quieto

  // Lógica de login
  Future<void> signIn(String email, String password) async {
    // Ponemos estado "Cargando" (la interfaz mostrará la ruedita girando)
    state = const AsyncValue.loading();
    
    // Intentamos hacer login
    // Guard nos permite manejar los errores automáticamente (guard = try/catch automático de Riverpod)
    state = await AsyncValue.guard(() => _authRepository.signIn(email, password));
  }

  // Lógica de registro
  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.register(email, password, name));
  }

  // Lógica de cierre de sesión
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authRepository.signOut());
  }
}