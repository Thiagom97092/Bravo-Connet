import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../post_card.dart';

class GrupoDetalleScreen extends StatefulWidget {
  final String grupoId;
  final Map<String, dynamic> grupoData;

  const GrupoDetalleScreen({
    super.key,
    required this.grupoId,
    required this.grupoData,
  });

  @override
  State<GrupoDetalleScreen> createState() => _GrupoDetalleScreenState();
}

class _GrupoDetalleScreenState extends State<GrupoDetalleScreen> {
  final TextEditingController postController = TextEditingController();
  File? imagenSeleccionada;

  Future<String?> subirImagen(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'posts/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imagenSeleccionada = File(picked.path);
      });
    }
  }

  void crearPost() async {
    if (postController.text.trim().isEmpty && imagenSeleccionada == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    // 🔥 OBTENER DATOS DEL USUARIO
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .get();

    final userData = userDoc.data();

    String? imageUrl;

    if (imagenSeleccionada != null) {
      imageUrl = await subirImagen(imagenSeleccionada!);
    }

    await FirebaseFirestore.instance
        .collection('grupos')
        .doc(widget.grupoId)
        .collection('posts')
        .add({
          'texto': postController.text.trim(),
          'imagen': imageUrl,
          'userId': user.uid,
          'userName': userData?['nombre'] ?? "Sin nombre", // ✅ CORREGIDO
          'userPhoto': userData?['foto'] ?? "",
          'fecha': FieldValue.serverTimestamp(),
        });

    postController.clear();
    setState(() => imagenSeleccionada = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.grupoData['nombre'] ?? "Grupo")),

      body: Column(
        children: [
          // 📝 CREAR POST
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: postController,
                        decoration: const InputDecoration(
                          hintText: "¿Qué estás pensando?",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: seleccionarImagen,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: crearPost,
                    ),
                  ],
                ),

                if (imagenSeleccionada != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(imagenSeleccionada!, height: 120),
                  ),
              ],
            ),
          ),

          // 📜 POSTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('grupos')
                  .doc(widget.grupoId)
                  .collection('posts')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    return PostCard(
                      grupoId: widget.grupoId,
                      postId: post.id,
                      data: post.data() as Map<String, dynamic>,
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
