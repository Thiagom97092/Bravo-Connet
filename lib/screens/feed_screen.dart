import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/post_service.dart';
import '../screens/comments_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();

    return Scaffold(
      appBar: AppBar(title: const Text("Feed")),
      body: StreamBuilder<QuerySnapshot>(
        stream: postService.getPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return const Center(child: Text("No hay publicaciones"));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              var post = posts[index];
              String postId = post.id;

              String currentUserId = FirebaseAuth.instance.currentUser!.uid;

              // ✅ VALIDACIÓN SEGURA
              if (post.data() == null) {
                return const SizedBox();
              }

              Map<String, dynamic> data = post.data() as Map<String, dynamic>;

              List likes = data.containsKey('likes') ? data['likes'] : [];

              bool isLiked = likes.contains(currentUserId);

              String userName = data['nombre'] ?? 'Usuario';
              String foto = data['fotoUsuario'] ?? '';
              String contenido = data['contenido'] ?? '';
              String imagenPost = data['imagenPost'] ?? '';

              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: foto.isNotEmpty
                                    ? NetworkImage(foto)
                                    : null,
                                child: foto.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          // 🗑 ELIMINAR
                          if (data['uid'] == currentUserId)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Eliminar post"),
                                    content: const Text(
                                      "¿Seguro que deseas eliminar este post?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await postService.deletePost(postId);
                                }
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 📝 TEXTO
                      if (contenido.isNotEmpty) Text(contenido),

                      const SizedBox(height: 10),

                      // 🖼 IMAGEN
                      if (imagenPost.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imagenPost,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text("Error cargando imagen");
                            },
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ❤️💬
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              postService.toggleLike(postId, currentUserId);
                            },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                          ),

                          Text("${likes.length} likes"),

                          const SizedBox(width: 20),

                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommentsScreen(
                                    postId: postId,
                                    userId: currentUserId,
                                    userName: userName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
