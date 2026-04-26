import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './feed_screen.dart';
import 'marketplace/marketplace_screen.dart';
import './chat/chat_list_screen.dart';
import './cafeterias/cafeterias_screen.dart';
import './grupos/grupos_screen.dart';
import './pascualizate/pascualizate_screen.dart';
import './profile/profile_screen.dart'; // 🔥 IMPORTANTE

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final user = FirebaseAuth.instance.currentUser;

  final List<Widget> _screens = [
    const FeedScreen(),
    const MarketplaceScreen(),
    const ChatListScreen(),
    const CafeteriasScreen(),
    const GruposScreen(),
    PascualizateScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bravo Connet"),

        // 🔥 FOTO PERFIL IZQUIERDA
        leading: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String? foto;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              foto = data['foto'];
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (foto != null && foto.isNotEmpty)
                      ? NetworkImage(foto)
                      : null,
                  child: (foto == null || foto.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
            );
          },
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text("¿Seguro que deseas salir?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Salir"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_cafe), label: 'Cafeterías'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Grupos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.psychology), label: 'Pascualízate'),
        ],
      ),
    );
  }
}
