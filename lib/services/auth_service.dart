import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Guardar datos del usuario en Firestore
  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userData = await userRef.get();

    if (!userData.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Usuario',
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Actualizar último login
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Registro con Email y Contraseña
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;
      
      if (user != null) {
        await user.updateDisplayName(name);
        await _saveUserToFirestore(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Login con Email y Contraseña
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // Login con Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        await _saveUserToFirestore(result.user!);
      }
      return result.user;
    } catch (e) {
      print("Error en Google Sign In: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
 // AÑADE ESTO: Función auxiliar para verificar si existe el campo 'nickname'
  Future<bool> userHasNickname(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      // Verificamos si el documento existe Y si tiene el campo 'nickname'
      return doc.exists && doc.data() != null && doc.data()!.containsKey('nickname');
    } catch (e) {
      return false; // Ante la duda, asumimos que no tiene
    }
  }

}
