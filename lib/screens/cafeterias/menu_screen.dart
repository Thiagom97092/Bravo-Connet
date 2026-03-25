import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatelessWidget {
  final String cafeteriaId;
  final String nombre;

  const MenuScreen({
    super.key,
    required this.cafeteriaId,
    required this.nombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nombre)),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cafeterias')
            .doc(cafeteriaId)
            .collection('menu')
            .snapshots(),

        builder: (context, snapshot) {
          // 🔄 Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error REAL (esto te dirá el problema)
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // ⚠️ Sin datos
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay productos"));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final rawData = items[index].data();

              // 🛑 PROTECCIÓN
              if (rawData == null) return const SizedBox();

              final data = rawData as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),

                child: ListTile(
                  leading: data['imagen'] != null && data['imagen'] != ''
                      ? Image.network(
                          data['imagen'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.fastfood),

                  title: Text(data['nombre'] ?? "Producto"),

                  subtitle: Text(data['descripcion'] ?? ""),

                  trailing: Text(
                    "\$${data['precio'] ?? '0'}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
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
