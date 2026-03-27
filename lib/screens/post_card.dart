import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostCard extends StatefulWidget {
  final String grupoId;
  final String postId;
  final Map<String, dynamic> data;

  const PostCard({
    super.key,
    required this.grupoId,
    required this.postId,
    required this.data,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController commentController = TextEditingController();
  File? imagenComentario;

  Future<String?> subirImagen(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'comentarios/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imagenComentario = File(picked.path);
      });
    }
  }

  void comentar() async {
    if (commentController.text.trim().isEmpty && imagenComentario == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final userData = userDoc.data();

    String? imageUrl;

    if (imagenComentario != null) {
      imageUrl = await subirImagen(imagenComentario!);
    }

    await FirebaseFirestore.instance
        .collection('grupos')
        .doc(widget.grupoId)
        .collection('posts')
        .doc(widget.postId)
        .collection('comentarios')
        .add({
          'texto': commentController.text.trim(),
          'imagen': imageUrl,
          'userId': user.uid,
          'userName': userData?['nombre'] ?? "Sin nombre", // ✅ CORREGIDO
          'userPhoto': userData?['foto'] ?? "",
          'fecha': FieldValue.serverTimestamp(),
        });

    commentController.clear();
    setState(() => imagenComentario = null);
  }

  @override
  Widget build(BuildContext context) {
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
                  backgroundImage:
                      widget.data['userPhoto'] != null &&
                          widget.data['userPhoto'] != ''
                      ? NetworkImage(widget.data['userPhoto'])
                      : null,
                  child:
                      (widget.data['userPhoto'] == null ||
                          widget.data['userPhoto'] == '')
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.data['userName'] != null &&
                          widget.data['userName'] != ''
                      ? widget.data['userName']
                      : "Sin nombre",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🧾 TEXTO
            if (widget.data['texto'] != null && widget.data['texto'] != '')
              Text(widget.data['texto']),

            // 🖼 IMAGEN
            if (widget.data['imagen'] != null && widget.data['imagen'] != '')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.network(widget.data['imagen']),
              ),

            const SizedBox(height: 10),

            // 💬 COMENTARIOS
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grupos')
                  .doc(widget.grupoId)
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comentarios')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final comentarios = snapshot.data!.docs;

                return Column(
                  children: comentarios.map((doc) {
                    final c = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            c['userPhoto'] != null && c['userPhoto'] != ''
                            ? NetworkImage(c['userPhoto'])
                            : null,
                        child: (c['userPhoto'] == null || c['userPhoto'] == '')
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        c['userName'] != null && c['userName'] != ''
                            ? c['userName']
                            : "Sin nombre",
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c['texto'] != null && c['texto'] != '')
                            Text(c['texto']),
                          if (c['imagen'] != null && c['imagen'] != '')
                            Image.network(c['imagen']),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // ✍️ COMENTAR
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(hintText: "Responder..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: seleccionarImagen,
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: comentar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
