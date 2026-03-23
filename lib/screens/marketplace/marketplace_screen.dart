import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/marketplace_service.dart';
import 'create_product_screen.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = MarketplaceService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Marketplace"), centerTitle: true),

      // ➕ BOTÓN CREAR PRODUCTO
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateProductScreen()),
          );
        },
      ),

      // 📡 STREAM DE PRODUCTOS
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getProducts(),
        builder: (context, snapshot) {
          // ⏳ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ ERROR
          if (snapshot.hasError) {
            return const Center(child: Text("Error cargando productos"));
          }

          // 📦 VALIDACIÓN DE DATA
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay productos"));
          }

          final products = snapshot.data!.docs;

          // 📋 LISTA
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];

              // 🔥 CORRECCIÓN DEL ERROR NULL
              var data = product.data();
              if (data == null) return const SizedBox();

              final productData = data as Map<String, dynamic>;

              String nombre = productData['nombre'] ?? '';
              String precio = productData['precio'] ?? '';
              String descripcion = productData['descripcion'] ?? '';
              String imagen = productData['imagen'] ?? '';
              String uid = productData['uid'] ?? '';

              return GestureDetector(
                onTap: () async {
                  final deleted = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        productData: productData,
                        productId: product.id,
                      ),
                    ),
                  );

                  // 🔥 SI SE ELIMINÓ DESDE DETALLE
                  if (deleted == true) {
                    await service.deleteProduct(product.id);
                  }
                },

                child: Card(
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼 IMAGEN
                      if (imagen.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            imagen,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      // 📄 INFO
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🛍 NOMBRE
                            Text(
                              nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            // 💰 PRECIO
                            Text(
                              "💰 $precio",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(height: 5),

                            // 📝 DESCRIPCIÓN (CORTA)
                            Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 10),

                            // 🗑 ELIMINAR (SOLO SI ES TUYO)
                            if (user != null && user.uid == uid)
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await service.deleteProduct(product.id);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Producto eliminado"),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
