import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'search_user_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUserScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 ORDEN CORRECTO DESDE FIRESTORE
        stream: ChatService().getUserChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("No tienes chats aún"));
          }

          // 🔥 ORDENAR POR ÚLTIMO MENSAJE (IMPORTANTE)
          chats.sort((a, b) {
            final t1 = a['lastTimestamp'];
            final t2 = b['lastTimestamp'];

            if (t1 == null || t2 == null) return 0;
            return t2.compareTo(t1); // 🔥 MÁS RECIENTE ARRIBA
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;

              final participants = List<String>.from(data['participants']);
              participants.remove(currentUser!.uid);
              final otherUserId = participants.first;

              // 🕒 HORA FORMATEADA
              String hora = "";
              if (data['lastTimestamp'] != null) {
                final date = (data['lastTimestamp'] as Timestamp).toDate();
                hora =
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
              }

              // 🔴 CONTADOR NO LEÍDOS
              int unread = 0;
              if (data['unreadCount'] != null &&
                  data['unreadCount'][currentUser.uid] != null) {
                unread = data['unreadCount'][currentUser.uid];
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;

                  if (userData == null) return const SizedBox();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
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
                            // 👤 FOTO
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: userData['foto'] != null &&
                                      userData['foto'] != ''
                                  ? NetworkImage(userData['foto'])
                                  : null,
                              child: userData['foto'] == null ||
                                      userData['foto'] == ''
                                  ? const Icon(Icons.person)
                                  : null,
                            ),

                            const SizedBox(width: 12),

                            // 📄 INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 👤 NOMBRE + HORA
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          userData['nombre'] ?? "Usuario",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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

                                  // 💬 MENSAJE + CONTADOR
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['lastMessage'] ?? "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: unread > 0
                                                ? Colors.black
                                                : Colors.grey[700],
                                            fontWeight: unread > 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),

                                      // 🔴 BADGE
                                      if (unread > 0)
                                        Container(
                                          margin:
                                              const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unread.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
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
