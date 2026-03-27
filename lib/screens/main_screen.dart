import 'package:flutter/material.dart';

import './home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import './chat/chat_list_screen.dart';
import './cafeterias/cafeterias_screen.dart';
import './grupos/grupos_screen.dart'; // 👈 NUEVO

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 🔥 LISTA DE PANTALLAS
  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketplaceScreen(),
    const ChatListScreen(),
    const CafeteriasScreen(),
    const GruposScreen(), // 👈 NUEVO
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_cafe),
            label: 'Cafeterías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group), // 👈 NUEVO
            label: 'Grupos',
          ),
        ],
      ),
    );
  }
}
