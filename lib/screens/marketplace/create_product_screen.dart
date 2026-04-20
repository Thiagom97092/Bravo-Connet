import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/storage_service.dart';
import '../../services/marketplace_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  File? image;
  bool isLoading = false;

  final picker = ImagePicker();
  final storageService = StorageService();
  final marketplaceService = MarketplaceService();

  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  void showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galería"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Cámara"),
              onTap: () {
                Navigator.pop(context);
                pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createProduct() async {
    if (nombreController.text.isEmpty || precioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa los campos obligatorios")),
      );
      return;
    }

    setState(() => isLoading = true);

    String imageUrl = '';

    if (image != null) {
      imageUrl = await storageService.uploadImage(image!, "products");
    }

    final user = FirebaseAuth.instance.currentUser;

    await marketplaceService.createProduct({
      'nombre': nombreController.text.trim(),
      'precio': precioController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'imagen': imageUrl,
      'uid': user!.uid,
      'fecha': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Nuevo producto"),
        actions: [
          TextButton(
            onPressed: createProduct,
            child: const Text(
              "Publicar",
              style: TextStyle(color: Colors.green),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // 📸 IMAGEN PRO
            GestureDetector(
              onTap: showImagePickerOptions,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40),
                          SizedBox(height: 10),
                          Text("Agregar imagen"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 CAMPOS PRO
            TextField(
              controller: nombreController,
              decoration: InputDecoration(
                hintText: "Nombre del producto",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Precio",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Descripción",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
