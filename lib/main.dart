import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Pantallas
import 'screens/auth/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 SOLUCIÓN DEFINITIVA PARA ANDROID (duplicate-app)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // 🔥 Evita crash si ya está inicializado (fallback seguro)
    debugPrint("Firebase ya estaba inicializado: $e");
  }

  runApp(const BravoConnetApp());
}

class BravoConnetApp extends StatelessWidget {
  const BravoConnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bravo Connet',
      debugShowCheckedModeBanner: false,

      // 🔥🔥🔥 TEMA PRO
      theme: ThemeData(
        useMaterial3: true,

        // 🎨 FONDO
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        // 🎨 COLORES
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006400),
          brightness: Brightness.light,
        ),

        // 🔝 APPBAR
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // 🧾 TARJETAS
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),

        // 🔘 BOTONES
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006400),
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 🔤 INPUTS
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),

        // 🔽 NAVBAR
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF006400),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),

        // 🧩 ICONOS
        iconTheme: const IconThemeData(
          color: Color(0xFF006400),
        ),

        // 🔤 TEXTO
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),

      // 🔥 RUTAS
      routes: {
        '/login': (context) => LoginScreen(),
        '/main': (context) => const MainScreen(),
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

    // 🔥 SI YA ESTÁ LOGUEADO → VA AL MAIN
    if (user != null) {
      return const MainScreen();
    } else {
      return LoginScreen();
    }
  }
}
