import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🔥 SUBIR IMAGEN GENÉRICA (PERFIL, POST, PRODUCTO)
  Future<String> uploadImage(File file, String folder) async {
    try {
      // 🧠 nombre único para evitar sobreescritura
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final ref = _storage.ref().child("$folder/$fileName.jpg");

      await ref.putFile(file);

      String downloadUrl = await ref.getDownloadURL();

      print("✅ URL IMAGEN: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print("❌ Error subiendo imagen: $e");
      throw Exception("No se pudo subir la imagen");
    }
  }

  // 👤 SOLO PERFIL (OPCIONAL)
  Future<String> uploadProfileImage(File file, String uid) async {
    try {
      final ref = _storage.ref().child("profile_images/$uid.jpg");

      await ref.putFile(file);

      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception("Error subiendo imagen de perfil");
    }
  }
}
