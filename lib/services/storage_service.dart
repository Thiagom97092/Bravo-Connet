import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔥 SUBIR IMAGEN DE PERFIL Y RETORNAR URL
  Future<String> uploadImage(File file, String uid) async {
    try {
      final ref = _storage.ref().child("profile_images/$uid.jpg");

      await ref.putFile(file);

      String downloadUrl = await ref.getDownloadURL();

      print("✅ URL IMAGEN: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print("❌ Error subiendo imagen: $e");
      throw Exception("No se pudo subir la imagen");
    }
  }
}
