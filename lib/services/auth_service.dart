import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 DETECTAR ROL AUTOMÁTICO
  String detectarRol(String email) {
    final domain = "@pascualbravo.edu.co";

    if (!email.endsWith(domain)) {
      throw Exception("Debes usar un correo institucional");
    }

    final tieneNumeros = RegExp(r'\d').hasMatch(email);

    if (tieneNumeros) {
      return "estudiante";
    } else {
      return "personal"; // docente / psicólogo
    }
  }

  // 🔥 REGISTRO CON ROL
  Future<Map<String, dynamic>?> register(String email, String password) async {
    try {
      final rol = detectarRol(email);

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'user': userCredential.user,
        'rol': rol,
      };
    } catch (e) {
      print("Error registro: $e");
      return null;
    }
  }

  // LOGIN
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
