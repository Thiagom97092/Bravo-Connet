import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(title: const Text("Chats")),

      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService().getUserChats(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando chats"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tienes chats aún"));
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),

            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              final participants = List<String>.from(data['participants']);
              participants.remove(currentUser!.uid);
              final otherUserId = participants.first;

              // 🕒 HORA (CORRECTA)
              String hora = "";
              if (data['lastTimestamp'] != null) {
                final timestamp = data['lastTimestamp'] as Timestamp;
                final date = timestamp.toDate();

                hora =
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(otherUserId)
                    .get(),

                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("Cargando..."),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),

                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(chatId: chat.id),
                          ),
                        );
                      },

                      child: Container(
                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            // 🖼 FOTO
                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  userData['foto'] != null &&
                                      userData['foto'] != ''
                                  ? NetworkImage(userData['foto'])
                                  : null,
                              child:
                                  userData['foto'] == null ||
                                      userData['foto'] == ''
                                  ? const Icon(Icons.person)
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            // 📄 TEXTO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 👤 NOMBRE + HORA
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        userData['nombre'] ?? "Usuario",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        hora,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  // 💬 MENSAJE
                                  Text(
                                    data['lastMessage'] != null &&
                                            data['lastMessage']
                                                .toString()
                                                .isNotEmpty
                                        ? data['lastMessage']
                                        : "Sin mensajes",
                                    style: TextStyle(color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
