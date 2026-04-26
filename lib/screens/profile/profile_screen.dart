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

  User? get user => FirebaseAuth.instance.currentUser;

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController passwordActualController =
      TextEditingController();
  final TextEditingController nuevaPasswordController = TextEditingController();

  File? imageFile;
  String? imageUrl;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;

    var data = await _firestoreService.getUser(user!.uid);

    if (data != null) {
      nombreController.text = data['nombre'] ?? '';
      imageUrl = data['foto'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<void> pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galería"),
              onTap: () {
                Navigator.pop(context);
                pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Cámara"),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateUser() async {
    if (user == null) return;

    final email = user!.email;

    if (email == null) return;

    String? url = imageUrl;

    if (imageFile != null) {
      url = await _storageService.uploadImage(imageFile!, user!.uid);
    }

    bool cambiarPassword = nuevaPasswordController.text.isNotEmpty;

    if (cambiarPassword) {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Actualizar contraseña"),
          content: const Text(
              "⚠️ Vas a cambiar tu contraseña y deberás iniciar sesión nuevamente."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Continuar")),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await _firestoreService.updateUser(
        uid: user!.uid,
        nombre: nombreController.text.trim(),
        foto: url,
      );

      if (cambiarPassword) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: passwordActualController.text.trim(),
        );

        await user!.reauthenticateWithCredential(credential);

        await user!.updatePassword(nuevaPasswordController.text.trim());

        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(imageUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: showImageOptions,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(controller: nombreController),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordActualController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nuevaPasswordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateUser,
                    child: const Text("Guardar cambios"),
                  )
                ],
              ),
            ),
    );
  }
}
