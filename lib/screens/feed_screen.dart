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

              Map<String, dynamic> data = post.data() as Map<String, dynamic>;

              List likes = data.containsKey('likes') ? data['likes'] : [];

              bool isLiked = likes.contains(currentUserId);

              String userName = data['nombre'] ?? 'Usuario';

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 USUARIO
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: data['fotoUsuario'] != ''
                                ? NetworkImage(data['fotoUsuario'])
                                : null,
                            child: data['fotoUsuario'] == ''
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 📝 TEXTO
                      Text(data['contenido'] ?? ''),

                      const SizedBox(height: 10),

                      // 🖼 IMAGEN
                      if (data['imagenPost'] != null &&
                          data['imagenPost'] != '')
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['imagenPost'],
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
                              color: isLiked ? Colors.red : null,
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
