import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'crear_grupo_screen.dart';
import 'grupo_detalle_screen.dart';

class GruposScreen extends StatelessWidget {
  const GruposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Grupos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearGrupoScreen()),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('grupos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay grupos"));
          }

          final grupos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: grupos.length,
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              final data = grupo.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['nombre'] ?? "Grupo"),
                  subtitle: Text(data['descripcion'] ?? ""),

                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.group, color: Colors.white),
                  ),

                  onTap: () async {
                    final userId = FirebaseAuth.instance.currentUser!.uid;

                    // 🔥 AGREGAR A MIEMBROS SI NO ESTÁ
                    if (data['miembros'] == null ||
                        !(data['miembros'] as List).contains(userId)) {
                      await FirebaseFirestore.instance
                          .collection('grupos')
                          .doc(grupo.id)
                          .update({
                            'miembros': FieldValue.arrayUnion([userId]),
                          });
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GrupoDetalleScreen(
                          grupoId: grupo.id,
                          grupoData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
