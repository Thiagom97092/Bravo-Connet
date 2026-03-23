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

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<void> updateUser() async {
    String? url = imageUrl;

    if (imageFile != null) {
      url = await _storageService.uploadImage(imageFile!, user!.uid);
    }

    print("📌 URL A GUARDAR: $url");

    await _firestoreService.updateUser(
      uid: user!.uid,
      nombre: nombreController.text.trim(),
      foto: url,
    );

    // 🔥 Recargar datos para reflejar cambios
    await loadUserData();

    setState(() {});

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
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: imageFile != null
                          ? FileImage(imageFile!)
                          : (imageUrl != null && imageUrl!.isNotEmpty)
                          ? NetworkImage(imageUrl!)
                          : null,
                      child:
                          imageFile == null &&
                              (imageUrl == null || imageUrl!.isEmpty)
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateUser,
                      child: const Text("Guardar cambios"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
