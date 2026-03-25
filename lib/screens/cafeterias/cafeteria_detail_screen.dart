import 'package:flutter/material.dart';
import 'menu_screen.dart';

class CafeteriaDetailScreen extends StatelessWidget {
  final String cafeteriaId;
  final Map<String, dynamic> cafeteriaData;

  const CafeteriaDetailScreen({
    super.key,
    required this.cafeteriaId,
    required this.cafeteriaData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(cafeteriaData['nombre'] ?? "Cafetería")),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🖼 IMAGEN
            cafeteriaData['imagen'] != null && cafeteriaData['imagen'] != ''
                ? Image.network(
                    cafeteriaData['imagen'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_cafe, size: 60),
                  ),

            const SizedBox(height: 20),

            // 📄 INFO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    cafeteriaData['nombre'] ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("📍 ${cafeteriaData['bloque'] ?? ""}"),
                  Text("⏰ ${cafeteriaData['horario'] ?? ""}"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 BOTÓN CON DEBUG
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text("Ver Menú"),

                  onPressed: () {
                    // 🔥 PRUEBA CLAVE
                    print("CAFETERIA ID: $cafeteriaId");
                    print("DATA: $cafeteriaData");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuScreen(
                          cafeteriaId: cafeteriaId,
                          nombre: cafeteriaData['nombre'] ?? "Menú",
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
