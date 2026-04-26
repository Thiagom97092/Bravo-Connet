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

  String? validarCorreo(String email) {
    if (!email.endsWith("@pascualbravo.edu.co")) {
      return "Debes usar tu correo institucional (@pascualbravo.edu.co)";
    }

    final usuario = email.split('@')[0];

    final tienePunto = usuario.contains('.');
    final tieneNumeros = RegExp(r'\d').hasMatch(usuario);

    if (!tienePunto) {
      return "El correo debe contener un punto (.) Ej: nombre.apellido";
    }

    if (tieneNumeros) {
      return null;
    } else {
      if (RegExp(r'\d').hasMatch(usuario)) {
        return "El correo de personal no debe contener números";
      }
      return null;
    }
  }

  String detectarRol(String email) {
    final usuario = email.split('@')[0];
    final tieneNumeros = RegExp(r'\d').hasMatch(usuario);

    return tieneNumeros ? "estudiante" : "personal";
  }

  void register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final nombre = nombreController.text.trim();

    if (email.isEmpty || password.isEmpty || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("⚠️ Por favor completa todos los campos para continuar"),
        ),
      );
      return;
    }

    final errorCorreo = validarCorreo(email);
    if (errorCorreo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $errorCorreo")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 La contraseña debe tener mínimo 6 caracteres"),
        ),
      );
      return;
    }

    try {
      final result = await _authService.register(email, password);

      if (result != null) {
        final user = result['user'];

        final rol = detectarRol(email);

        await _firestoreService.saveUser(
          uid: user.uid,
          email: email,
          nombre: nombre,
          rol: rol,
        );

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
          SnackBar(
            content: Text(
                "✅ Registro exitoso como ${rol == "estudiante" ? "Estudiante" : "Personal de apoyo"}"),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("❌ No se pudo completar el registro. Intenta nuevamente"),
          ),
        );
      }
    } catch (e) {
      String mensaje = "❌ Error inesperado";

      if (e.toString().contains('email-already-in-use')) {
        mensaje = "⚠️ Este correo ya está registrado";
      } else if (e.toString().contains('invalid-email')) {
        mensaje = "⚠️ El formato del correo no es válido";
      } else if (e.toString().contains('weak-password')) {
        mensaje = "⚠️ La contraseña es demasiado débil";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro")),
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

              const Text(
                "Crear cuenta",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Correo institucional",
                  hintText: "ej: nombre.apellido123@pascualbravo.edu.co",
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
              const SizedBox(height: 25),

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
      ),
    );
  }
}
