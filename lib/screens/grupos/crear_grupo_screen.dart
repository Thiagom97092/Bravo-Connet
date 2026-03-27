import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CrearGrupoScreen extends StatefulWidget {
  const CrearGrupoScreen({super.key});

  @override
  State<CrearGrupoScreen> createState() => _CrearGrupoScreenState();
}

class _CrearGrupoScreenState extends State<CrearGrupoScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  void crearGrupo() async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('grupos').add({
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'adminId': user!.uid,
      'miembros': [user.uid],
      'fecha': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Grupo creado correctamente")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Grupo")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre del grupo",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: crearGrupo,
                child: const Text("Crear Grupo"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
