import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/post_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String userId;
  final String userName;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.userId,
    required this.userName,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final PostService _postService = PostService();
  final TextEditingController _controller = TextEditingController();

  void _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    await _postService.addComment(
      postId: widget.postId,
      uid: widget.userId,
      nombre: widget.userName,
      comentario: _controller.text.trim(),
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comentarios")),
      body: Column(
        children: [
          // 💬 LISTA DE COMENTARIOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postService.getComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(child: Text("No hay comentarios"));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var data = comments[index].data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['nombre'] ?? 'Usuario'),
                      subtitle: Text(data['comentario'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          // ✏️ INPUT
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe un comentario...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
