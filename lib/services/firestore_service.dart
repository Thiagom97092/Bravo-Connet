import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 GUARDAR USUARIO
  Future<void> saveUser({
    required String uid,
    required String email,
    required String nombre,
    required String rol,
  }) async {
    await _db.collection('usuarios').doc(uid).set({
      'email': email,
      'nombre': nombre,
      'rol': rol,
      'foto': '', // 👈 IMPORTANTE (foto de perfil)
      'fecha_registro': DateTime.now(),
    });
  }

  // 🔥 OBTENER USUARIO
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error obteniendo usuario: $e");
    }

    return null;
  }

  // 🔥 ACTUALIZAR USUARIO (NOMBRE Y/O FOTO)
  Future<void> updateUser({
    required String uid,
    String? nombre,
    String? foto,
  }) async {
    try {
      Map<String, dynamic> data = {};

      if (nombre != null) {
        data['nombre'] = nombre;
      }

      if (foto != null) {
        data['foto'] = foto;
      }

      await _db.collection('usuarios').doc(uid).update(data);
    } catch (e) {
      print("Error actualizando usuario: $e");
    }
  }

  // 🔥 ELIMINAR USUARIO (OPCIONAL - FUTURO)
  Future<void> deleteUser(String uid) async {
    try {
      await _db.collection('usuarios').doc(uid).delete();
    } catch (e) {
      print("Error eliminando usuario: $e");
    }
  }
}
