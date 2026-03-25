import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buscar usuarios")),

      body: Column(
        children: [
          // 🔍 BUSCADOR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o correo",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // 📄 RESULTADOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;

                // 🔥 FILTRAR
                final filteredUsers = users.where((user) {
                  final data = user.data() as Map<String, dynamic>;

                  final nombre = (data['nombre'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();

                  return nombre.contains(searchText) ||
                      email.contains(searchText);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text("No se encontraron usuarios"),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final userDoc = filteredUsers[index];
                    final data = userDoc.data() as Map<String, dynamic>;

                    // 🚫 NO MOSTRARSE A SÍ MISMO
                    if (userDoc.id == currentUser!.uid) {
                      return const SizedBox();
                    }

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            data['foto'] != null && data['foto'] != ''
                            ? NetworkImage(data['foto'])
                            : null,
                        child: data['foto'] == ''
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      title: Text(data['nombre'] ?? "Usuario"),
                      subtitle: Text(data['email'] ?? ""),

                      // 🚀 INICIAR CHAT
                      onTap: () async {
                        final chatId = await ChatService().createOrGetChat(
                          userDoc.id,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chatId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
