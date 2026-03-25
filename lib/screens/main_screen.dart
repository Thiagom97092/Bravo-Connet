import 'package:flutter/material.dart';

import './home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import './chat/chat_list_screen.dart';
import './cafeterias/cafeterias_screen.dart'; // ☕ NUEVO

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketplaceScreen(),
    const ChatListScreen(),
    const CafeteriasScreen(), // ☕ NUEVO
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // ✅ IMPORTANTE para tablets y móviles grandes
        child: _screens[_currentIndex],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green, // 👈 estilo app
        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed, // ✅ necesario para +3 items

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_cafe), // ☕ CAFETERÍAS
            label: 'Cafeterías',
          ),
        ],
      ),
    );
  }
}
