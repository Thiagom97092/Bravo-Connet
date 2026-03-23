import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../feed_screen.dart';
import '../create_post_screen.dart';
import '../marketplace/marketplace_screen.dart'; // ✅ NUEVO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      var data = await _firestoreService.getUser(user!.uid);

      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bravo Connet"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("Error cargando usuario"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 👤 FOTO + NOMBRE
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        userData!['foto'] != null && userData!['foto'] != ''
                        ? NetworkImage(userData!['foto'])
                        : null,
                    child: userData!['foto'] == null || userData!['foto'] == ''
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userData!['nombre'] ?? "Usuario",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 BOTONES PRINCIPALES
                  buildButton(
                    text: "Ir a Perfil",
                    icon: Icons.person,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  buildButton(
                    text: "Ver publicaciones",
                    icon: Icons.feed,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedScreen()),
                      );
                    },
                  ),

                  buildButton(
                    text: "Crear publicación",
                    icon: Icons.add_box,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                    },
                  ),

                  // 🛒 NUEVO MÓDULO MARKETPLACE
                  buildButton(
                    text: "Marketplace",
                    icon: Icons.store,
                    color: Colors.green,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MarketplaceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // 🔧 BOTÓN REUTILIZABLE (UI PRO)
  Widget buildButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(icon),
          label: Text(text),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
