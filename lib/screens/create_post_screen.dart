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

  final ImagePicker _picker = ImagePicker();

  // 📸 GALERÍA
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // 📷 CÁMARA
  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  // 🔥 MODAL (como Facebook / Instagram)
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tomar foto"),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Elegir de galería"),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 CREAR POST
  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    String imageUrl = '';

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
      contenido: _contenidoController.text.trim(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✍️ TEXTO
            TextField(
              controller: _contenidoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "¿Qué estás pensando?",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            // 🖼 PREVIEW IMAGEN
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_imageFile!, height: 180),
              ),

            const SizedBox(height: 15),

            // 📸 BOTÓN IMAGEN
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showImageOptions,
                  icon: const Icon(Icons.image),
                  label: const Text("Agregar imagen"),
                ),

                const SizedBox(width: 10),

                // ❌ QUITAR IMAGEN
                if (_imageFile != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                      });
                    },
                  ),
              ],
            ),

            const Spacer(),

            // 🚀 PUBLICAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createPost,
                child: const Text("Publicar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
