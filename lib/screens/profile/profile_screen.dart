import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController nombreController = TextEditingController();

  File? imageFile;
  String? imageUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    var data = await _firestoreService.getUser(user!.uid);

    if (data != null) {
      nombreController.text = data['nombre'] ?? '';
      imageUrl = data['foto'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  // 🔥 SELECCIONAR DESDE GALERÍA
  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // 🔥 TOMAR FOTO CON CÁMARA
  Future<void> pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // 🔥 MOSTRAR OPCIONES
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Elegir de galería"),
                onTap: () {
                  Navigator.pop(context);
                  pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Tomar foto"),
                onTap: () {
                  Navigator.pop(context);
                  pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateUser() async {
    String? url = imageUrl;

    if (imageFile != null) {
      url = await _storageService.uploadImage(imageFile!, user!.uid);
    }

    await _firestoreService.updateUser(
      uid: user!.uid,
      nombre: nombreController.text.trim(),
      foto: url,
    );

    await loadUserData();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Perfil actualizado")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 🔥 FOTO DE PERFIL
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: showImageOptions,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: imageFile != null
                              ? FileImage(imageFile!)
                              : (imageUrl != null && imageUrl!.isNotEmpty)
                              ? NetworkImage(imageUrl!)
                              : null,
                          child:
                              imageFile == null &&
                                  (imageUrl == null || imageUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                      ),

                      // 🔥 ICONO CÁMARA
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: showImageOptions,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🔥 NOMBRE
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔥 BOTÓN GUARDAR
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Guardar cambios",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
