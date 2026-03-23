import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Pantallas
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const BravoConnetApp());
}

class BravoConnetApp extends StatelessWidget {
  const BravoConnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bravo Connet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),

      // 🔥 RUTAS
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
      },

      // 🔥 CONTROL DE SESIÓN
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const MainScreen(); // 🔥 CAMBIO AQUÍ
    } else {
      return LoginScreen();
    }
  }
}
