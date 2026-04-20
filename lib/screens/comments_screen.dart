import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/post_service.dart';
import '../services/firestore_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String userId;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final PostService _postService = PostService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _controller = TextEditingController();

  String userName = "Usuario"; // 🔥 nombre real dinámico

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // 🔥 OBTENER NOMBRE REAL DEL USUARIO LOGUEADO
  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final data = await _firestoreService.getUser(user.uid);

      if (data != null) {
        setState(() {
          userName = data['nombre'] ?? "Usuario";
        });
      }
    } catch (e) {
      print("Error cargando usuario: $e");
    }
  }

  void _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    await _postService.addComment(
      postId: widget.postId,
      uid: widget.userId,
      nombre: userName, // 🔥 AHORA SÍ ES EL CORRECTO
      comentario: _controller.text.trim(),
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comentarios"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔥 LISTA DE COMENTARIOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aún no hay comentarios",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var data = comments[index].data() as Map<String, dynamic>;

                    String nombre = data['nombre'] ?? "Usuario";
                    String comentario = data['comentario'] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            child: Icon(Icons.person, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(comentario),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔥 INPUT
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Escribe un comentario...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
