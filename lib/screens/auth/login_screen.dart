import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Ingresa tu correo y contraseña"),
        ),
      );
      return;
    }

    var user = await _authService.login(email, password);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "❌ No se pudo iniciar sesión. Verifica tus datos o tu conexión"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bravo Connet")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          // 🔥 evita overflow
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🔥 LOGO CIRCULAR
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: const AssetImage('assets/logo.png'),
              ),

              const SizedBox(height: 20),

              // 🔥 TITULO OPCIONAL
              const Text(
                "Bienvenido",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Correo institucional",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => login(context),
                  child: const Text("Iniciar Sesión"),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: const Text("Crear cuenta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
