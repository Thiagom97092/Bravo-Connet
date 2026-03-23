import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ FALTABA

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

  // 📸 SELECCIONAR IMAGEN
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = File(picked.path);
      });
    }
  }

  // 🚀 CREAR PRODUCTO
  Future<void> createProduct() async {
    if (nombreController.text.isEmpty || precioController.text.isEmpty) {
      return;
    }

    setState(() => isLoading = true);

    String imageUrl = '';

    // 🔥 CORRECCIÓN AQUÍ
    if (image != null) {
      imageUrl = await storageService.uploadImage(image!, "products");
    }

    final user = FirebaseAuth.instance.currentUser;

    await marketplaceService.createProduct({
      'nombre': nombreController.text,
      'precio': precioController.text,
      'descripcion': descripcionController.text,
      'imagen': imageUrl,
      'uid': user!.uid,
      'fecha': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Producto")),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: image == null
                  ? Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo),
                    )
                  : Image.file(image!, height: 150),
            ),

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),

            TextField(
              controller: precioController,
              decoration: const InputDecoration(labelText: "Precio"),
            ),

            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: createProduct,
                    child: const Text("Publicar"),
                  ),
          ],
        ),
      ),
    );
  }
}
