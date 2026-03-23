import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceService {
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

  // 📥 OBTENER PRODUCTOS
  Stream<QuerySnapshot> getProducts() {
    return products.orderBy('fecha', descending: true).snapshots();
  }

  // ➕ CREAR PRODUCTO
  Future<void> createProduct(Map<String, dynamic> data) async {
    await products.add(data);
  }

  // ❌ ELIMINAR PRODUCTO
  Future<void> deleteProduct(String productId) async {
    await products.doc(productId).delete();
  }
}
