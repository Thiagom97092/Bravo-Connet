import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

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
  File? _videoFile;
  VideoPlayerController? _videoController;

  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  final ImagePicker _picker = ImagePicker();

  // 📸 IMAGEN
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _videoFile = null;
      });
    }
  }

  // 🎥 VIDEO
  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source);

    if (picked != null) {
      _initVideo(File(picked.path));
    }
  }

  void _initVideo(File file) {
    _videoController?.dispose();

    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _videoFile = file;
          _imageFile = null;
        });
        _videoController!.play();
      });
  }

  // 🔥 MODAL
  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                "Selecciona contenido",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Imagen (Galería)"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tomar foto"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text("Video (Galería)"),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Grabar video"),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
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
    String videoUrl = '';

    if (_imageFile != null) {
      imageUrl = await _storageService.uploadImage(_imageFile!, "posts");
    }

    if (_videoFile != null) {
      videoUrl = await _storageService.uploadImage(_videoFile!, "videos");
    }

    final userData = await _firestoreService.getUser(user.uid);

    await _postService.createPost(
      uid: user.uid,
      nombre: userData?['nombre'] ?? 'Usuario',
      fotoUsuario: userData?['foto'] ?? '',
      contenido: _contenidoController.text.trim(),
      imagenPost: imageUrl,
      videoPost: videoUrl,
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canPost = _contenidoController.text.trim().isNotEmpty ||
        _imageFile != null ||
        _videoFile != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Crear publicación"),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: canPost ? _createPost : null,
            child: Text(
              "Publicar",
              style: TextStyle(
                color: canPost ? Colors.green[700] : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 🔥 INPUT CARD
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _contenidoController,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: "¿Qué estás pensando?",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 PREVIEW
          if (_imageFile != null || _videoFile != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _imageFile != null
                        ? Image.file(_imageFile!)
                        : AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                  ),

                  // ❌ BOTÓN CERRAR
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                          _videoFile = null;
                          _videoController?.dispose();
                        });
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),

          const Spacer(),

          // 🔥 BOTÓN GRANDE
          Padding(
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text(
                  "Agregar foto o video",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
