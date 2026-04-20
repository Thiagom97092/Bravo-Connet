import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    String nombre = productData['nombre'] ?? '';
    String precio = productData['precio'] ?? '';
    String descripcion = productData['descripcion'] ?? '';
    String imagen = productData['imagen'] ?? '';
    String uid = productData['uid'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),

      appBar: AppBar(
        title: const Text("Producto"),
        elevation: 0,
      ),

      // 🔥 BOTÓN FIJO ABAJO (UX PRO)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: user != null && user.uid != uid
            ? ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text(
                  "Contactar vendedor",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () async {
                  try {
                    final chatService = ChatService();

                    String chatId = await chatService.createOrGetChat(uid);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chatId),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
              )
            : user != null && user.uid == uid
                ? ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text("Eliminar producto"),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  )
                : const SizedBox(),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔥 IMAGEN HERO
            Stack(
              children: [
                imagen.isNotEmpty
                    ? Image.network(
                        imagen,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 60),
                        ),
                      ),

                // 🔥 OVERLAY GRADIENT (PRO)
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black45,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // 💰 PRECIO SOBRE IMAGEN
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Text(
                    "\$$precio",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // 🔥 CONTENIDO EN TARJETA
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🛍 NOMBRE
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 💰 PRECIO (REFUERZO)
                    Text(
                      "\$$precio",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 📄 DIVIDER
                    const Divider(),

                    const SizedBox(height: 10),

                    // 📝 TITULO DESCRIPCIÓN
                    const Text(
                      "Descripción",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 📝 TEXTO
                    Text(
                      descripcion.isNotEmpty ? descripcion : "Sin descripción",
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 80), // espacio para botón
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
