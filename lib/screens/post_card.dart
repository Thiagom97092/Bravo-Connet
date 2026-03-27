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

  final currentUser = FirebaseAuth.instance.currentUser;

  // 🔥 SUBIR IMAGEN
  Future<String?> subirImagen(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
      'comentarios/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 🔥 SELECCIONAR IMAGEN (GALERÍA O CÁMARA)
  Future<void> seleccionarImagen() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Galería"),
            onTap: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                setState(() => imagenComentario = File(picked.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Cámara"),
            onTap: () async {
              Navigator.pop(context);
              final picked = await ImagePicker().pickImage(
                source: ImageSource.camera,
              );
              if (picked != null) {
                setState(() => imagenComentario = File(picked.path));
              }
            },
          ),
        ],
      ),
    );
  }

  // 🔥 COMENTAR
  void comentar() async {
    if (commentController.text.trim().isEmpty && imagenComentario == null) {
      return;
    }

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
          'userId': currentUser!.uid, // ✅ SOLO ID
          'fecha': FieldValue.serverTimestamp(),
        });

    commentController.clear();
    setState(() => imagenComentario = null);
  }

  // 🔥 ELIMINAR POST
  Future<void> eliminarPost() async {
    await FirebaseFirestore.instance
        .collection('grupos')
        .doc(widget.grupoId)
        .collection('posts')
        .doc(widget.postId)
        .delete();
  }

  void confirmarEliminarPost() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar publicación"),
        content: const Text("¿Seguro que deseas eliminar esta publicación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              eliminarPost();
              Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUser!.uid == widget.data['userId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.data['userId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        final nombre = userData?['nombre'] ?? "Sin nombre";
        final foto = userData?['foto'] ?? "";

        return Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 HEADER DINÁMICO
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: foto.isNotEmpty
                          ? NetworkImage(foto)
                          : null,
                      child: foto.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    if (isOwner)
                      PopupMenuButton(
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'eliminar',
                            child: Text("Eliminar"),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'eliminar') {
                            confirmarEliminarPost();
                          }
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                if (widget.data['texto'] != null) Text(widget.data['texto']),

                if (widget.data['imagen'] != null)
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

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(c['userId'])
                              .get(),
                          builder: (context, snapUser) {
                            if (!snapUser.hasData) return const SizedBox();

                            final user =
                                snapUser.data!.data() as Map<String, dynamic>?;

                            final nombre = user?['nombre'] ?? "Sin nombre";
                            final foto = user?['foto'] ?? "";

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: foto.isNotEmpty
                                    ? NetworkImage(foto)
                                    : null,
                                child: foto.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(nombre),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c['texto'] != null) Text(c['texto']),
                                  if (c['imagen'] != null)
                                    Image.network(c['imagen']),
                                ],
                              ),
                            );
                          },
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
                        decoration: const InputDecoration(
                          hintText: "Responder...",
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: seleccionarImagen,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: comentar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
