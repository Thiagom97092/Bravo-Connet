import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/marketplace_service.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();

  File? _imageFile;

  final MarketplaceService _service = MarketplaceService();
  final StorageService _storage = StorageService();
  final FirestoreService _firestore = FirestoreService();

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _createProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String imageUrl = '';

    if (_imageFile != null) {
      imageUrl = await _storage.uploadImage(
        _imageFile!,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }

    final userData = await _firestore.getUser(user.uid);

    String nombreUsuario = userData?['nombre'] ?? 'Usuario';

    await _service.createProduct(
      nombre: _nombreController.text,
      descripcion: _descripcionController.text,
      precio: double.tryParse(_precioController.text) ?? 0,
      imagen: imageUrl,
      uid: user.uid,
      nombreUsuario: nombreUsuario,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vender producto")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),
            TextField(
              controller: _precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Precio"),
            ),

            const SizedBox(height: 10),

            if (_imageFile != null) Image.file(_imageFile!, height: 120),

            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Seleccionar imagen"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _createProduct,
              child: const Text("Publicar producto"),
            ),
          ],
        ),
      ),
    );
  }
}
