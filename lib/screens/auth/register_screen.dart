import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // 🔥 DETECTAR ROL AUTOMÁTICO
  String detectarRol(String email) {
    final correo = email.split('@')[0];

    final tieneNumeros = RegExp(r'\d').hasMatch(correo);

    if (tieneNumeros) {
      return "estudiante";
    } else {
      return "personal"; // incluye psicólogos/docentes
    }
  }

  void register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();

    // 🔥 VALIDACIÓN
    if (email.isEmpty || password.isEmpty || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    // 🔥 VALIDAR DOMINIO INSTITUCIONAL
    if (!email.endsWith("@pascualbravo.edu.co")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usa tu correo institucional")),
      );
      return;
    }

    try {
      final result = await _authService.register(email, password);

      if (result != null) {
        final user = result['user'];

        // 🔥 DETECTAR ROL
        final rol = detectarRol(email);

        // 🔥 GUARDAR USUARIO
        await _firestoreService.saveUser(
          uid: user.uid,
          email: email,
          nombre: nombre,
          rol: rol,
        );

        // 🔥 SI ES PERSONAL → CREAR EN PSICÓLOGOS
        if (rol == "personal") {
          await FirebaseFirestore.instance
              .collection('psicologos')
              .doc(user.uid)
              .set({
            'nombre': nombre,
            'email': email,
            'foto': '',
            'especialidad': 'Psicología',
            'activo': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrado como $rol ✅")),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error en el registro")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 Nombre
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 📧 Correo
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Correo institucional",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // 🔒 Contraseña
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "Contraseña",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 25),

            // 🔥 BOTÓN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => register(context),
                child: const Text("Registrarse"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
