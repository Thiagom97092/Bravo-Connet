import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/post_service.dart';
import '../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contenidoController = TextEditingController();

  File? _imageFile;

  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  // 📸 SELECCIONAR IMAGEN
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // 🚀 CREAR POST
  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    String imageUrl = '';

    // 🔥 SUBIR IMAGEN SI EXISTE
    if (_imageFile != null) {
      imageUrl = await _storageService.uploadImage(
        _imageFile!,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }

    await _postService.createPost(
      uid: user.uid,
      nombre: user.displayName ?? 'Usuario',
      fotoUsuario: user.photoURL ?? '',
      contenido: _contenidoController.text,
      imagenPost: imageUrl, // 🔥 URL REAL
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear publicación")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📝 TEXTO
            TextField(
              controller: _contenidoController,
              decoration: const InputDecoration(
                hintText: "¿Qué estás pensando?",
              ),
            ),

            const SizedBox(height: 10),

            // 🖼 PREVIEW
            if (_imageFile != null) Image.file(_imageFile!, height: 150),

            const SizedBox(height: 10),

            // 📸 BOTÓN IMAGEN
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Seleccionar imagen"),
            ),

            const SizedBox(height: 20),

            // 🚀 PUBLICAR
            ElevatedButton(
              onPressed: _createPost,
              child: const Text("Publicar"),
            ),
          ],
        ),
      ),
    );
  }
}
