import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🛒 CREAR PRODUCTO
  Future<void> createProduct({
    required String nombre,
    required String descripcion,
    required double precio,
    required String imagen,
    required String uid,
    required String nombreUsuario,
  }) async {
    await _db.collection('productos').add({
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagen': imagen,
      'uid': uid,
      'nombreUsuario': nombreUsuario,
      'fecha': DateTime.now(),
    });
  }

  // 📦 OBTENER PRODUCTOS
  Stream<QuerySnapshot> getProducts() {
    return _db
        .collection('productos')
        .orderBy('fecha', descending: true)
        .snapshots();
  }
}
