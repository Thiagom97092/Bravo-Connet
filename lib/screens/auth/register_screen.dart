import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void register(BuildContext context) async {
    try {
      var user = await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user != null) {
        await _firestoreService.saveUser(
          uid: user.uid,
          email: emailController.text.trim(),
          nombre: nombreController.text.trim(),
          rol: "usuario",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario registrado correctamente")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
                labelText: "Correo",
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

            // 🔥 Botón registrar
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
