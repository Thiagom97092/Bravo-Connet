import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/post_service.dart';
import '../screens/comments_screen.dart';
import '../screens/create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();
    final user = FirebaseAuth.instance.currentUser;

    // 🔥 VALIDACIÓN: evita crash cuando el usuario es null
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Sesión expirada. Inicia sesión nuevamente"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          "Bravo Connet",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔥 CREAR POST (foto dinámica)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String foto = "";

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                foto = data['foto'] ?? "";
              }

              return Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePostScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          backgroundImage:
                              foto.isNotEmpty ? NetworkImage(foto) : null,
                          child: foto.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "¿Qué estás pensando?",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Icon(Icons.image, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 🔥 LISTA DE POSTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: postService.getPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return const Center(child: Text("No hay publicaciones"));
                }

                final currentUser = FirebaseAuth.instance.currentUser;

                if (currentUser == null) {
                  return const Center(child: Text("Sesión expirada"));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    String postId = post.id;

                    String currentUserId = currentUser.uid;

                    Map<String, dynamic> data =
                        post.data() as Map<String, dynamic>;

                    List likes = data['likes'] ?? [];
                    bool isLiked = likes.contains(currentUserId);

                    return _PostCard(
                      postId: postId,
                      isOwner: data['uid'] == currentUserId,
                      userName: data['nombre'] ?? 'Usuario',
                      foto: data['fotoUsuario'] ?? '',
                      contenido: data['contenido'] ?? '',
                      imagenPost: data['imagenPost'] ?? '',
                      isLiked: isLiked,
                      likesCount: likes.length,
                      onLike: () =>
                          postService.toggleLike(postId, currentUserId),
                      onComment: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentsScreen(
                              postId: postId,
                              userId: currentUserId,
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        await postService.deletePost(postId);
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

class _PostCard extends StatefulWidget {
  final String postId;
  final bool isOwner;
  final String userName;
  final String foto;
  final String contenido;
  final String imagenPost;
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onDelete;

  const _PostCard({
    required this.postId,
    required this.isOwner,
    required this.userName,
    required this.foto,
    required this.contenido,
    required this.imagenPost,
    required this.isLiked,
    required this.likesCount,
    required this.onLike,
    required this.onComment,
    required this.onDelete,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  bool liked = false;

  @override
  void initState() {
    super.initState();

    liked = widget.isLiked;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scale = Tween(begin: 1.0, end: 1.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateLike() async {
    await _controller.forward();
    await _controller.reverse();
  }

  void showDeleteDialog() async {
    if (!widget.isOwner) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar post"),
        content: const Text("¿Seguro que deseas eliminar este post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: showDeleteDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    widget.foto.isNotEmpty ? NetworkImage(widget.foto) : null,
                child: widget.foto.isEmpty ? const Icon(Icons.person) : null,
              ),
              title: Text(widget.userName),
            ),
            if (widget.contenido.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(widget.contenido),
              ),
            if (widget.imagenPost.isNotEmpty)
              Image.network(
                widget.imagenPost,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => liked = !liked);
                    animateLike();
                    widget.onLike();
                  },
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: widget.onComment,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text("${widget.likesCount} Me gusta"),
            ),
          ],
        ),
      ),
    );
  }
}
