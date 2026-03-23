import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔥 IMPORTS DEL CHAT
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
      appBar: AppBar(
        title: const Text("Detalle del producto"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 IMAGEN
            if (imagen.isNotEmpty)
              Image.network(
                imagen,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(15),
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

                  // 💰 PRECIO
                  Text(
                    "💰 $precio",
                    style: const TextStyle(fontSize: 18, color: Colors.green),
                  ),

                  const SizedBox(height: 15),

                  // 📝 DESCRIPCIÓN
                  const Text(
                    "Descripción",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(descripcion),

                  const SizedBox(height: 30),

                  // 💬 BOTÓN CONTACTAR (CHAT REAL 🔥)
                  if (user != null && user.uid != uid)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text("Contactar vendedor"),
                        onPressed: () async {
                          try {
                            final chatService = ChatService();

                            // 🔥 CREAR OBTENER CHAT
                            String chatId = await chatService.createOrGetChat(
                              uid,
                            );

                            // 🚀 IR AL CHAT
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(chatId: chatId),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error al abrir chat: $e"),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                  // 🗑 SI ES EL DUEÑO
                  if (user != null && user.uid == uid)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text("Eliminar producto"),
                        onPressed: () {
                          Navigator.pop(context, true);
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
  }
}
