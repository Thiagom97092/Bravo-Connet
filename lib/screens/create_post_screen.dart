import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

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
  final FirestoreService _firestoreService = FirestoreService();

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

    // 🔥 CORRECCIÓN AQUÍ
    if (_imageFile != null) {
      imageUrl = await _storageService.uploadImage(_imageFile!, "posts");
    }

    String nombre = 'Usuario';
    String foto = '';

    try {
      final userData = await _firestoreService.getUser(user.uid);

      if (userData != null) {
        nombre = userData['nombre'] ?? 'Usuario';
        foto = userData['foto'] ?? '';
      }
    } catch (e) {
      print("Error obteniendo usuario: $e");
    }

    await _postService.createPost(
      uid: user.uid,
      nombre: nombre,
      fotoUsuario: foto,
      contenido: _contenidoController.text,
      imagenPost: imageUrl,
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
            TextField(
              controller: _contenidoController,
              decoration: const InputDecoration(
                hintText: "¿Qué estás pensando?",
              ),
            ),

            const SizedBox(height: 10),

            if (_imageFile != null) Image.file(_imageFile!, height: 150),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Seleccionar imagen"),
            ),

            const SizedBox(height: 20),

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
