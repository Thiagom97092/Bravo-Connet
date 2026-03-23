import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../feed_screen.dart';
import '../create_post_screen.dart';

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
    var data = await _firestoreService.getUser(user!.uid);

    setState(() {
      userData = data;
      isLoading = false;
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("Error cargando usuario"))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔥 FOTO + NOMBRE
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
                    userData!['nombre'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔥 BOTONES
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: const Text("Ir a Perfil"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedScreen()),
                        );
                      },
                      child: const Text("Ver publicaciones"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreatePostScreen(),
                          ),
                        );
                      },
                      child: const Text("Crear publicación"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
