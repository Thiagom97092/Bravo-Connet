import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/citas_service.dart';
import '../../services/firestore_service.dart';
import 'agenda_screen.dart';

class PascualizateScreen extends StatefulWidget {
  const PascualizateScreen({super.key});

  @override
  State<PascualizateScreen> createState() => _PascualizateScreenState();
}

class _PascualizateScreenState extends State<PascualizateScreen> {
  final CitasService _service = CitasService();
  final FirestoreService _firestoreService = FirestoreService();

  final user = FirebaseAuth.instance.currentUser;

  String rol = "";
  String uid = "";
  String nombre = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final data = await _firestoreService.getUser(user!.uid);

    setState(() {
      rol = data?['rol'] ?? '';
      uid = user!.uid;
      nombre = data?['nombre'] ?? 'Usuario';
    });
  }

  @override
  Widget build(BuildContext context) {
    final esPsicologo = rol == "psicologo" || rol == "personal";

    return Scaffold(
      // 🔥 APPBAR CON LOGOUT (IGUAL QUE MAIN)
      appBar: AppBar(
        title: const Text("Pascualízate 🧠"),
        actions: [
          /*IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cerrar sesión"),
                  content: const Text("¿Seguro que deseas salir?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Salir"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await FirebaseAuth.instance.signOut();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),*/
        ],
      ),

      body: esPsicologo ? buildPsicologoView() : buildEstudianteView(),
    );
  }

  // 🔥 VISTA PARA PSICÓLOGO (SOLO SU AGENDA)
  Widget buildPsicologoView() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          "Mi Agenda",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: AgendaScreen(
            psicologoId: uid, // 🔥 SOLO EL USUARIO LOGUEADO
            psicologoNombre: nombre,
          ),
        ),
      ],
    );
  }

  // 🔥 VISTA PARA ESTUDIANTE (LISTA DE PSICÓLOGOS)
  Widget buildEstudianteView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _service.getPsicologos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No hay psicólogos disponibles"),
          );
        }

        final psicologos = snapshot.data!.docs;

        return ListView.builder(
          itemCount: psicologos.length,
          itemBuilder: (context, index) {
            final doc = psicologos[index];
            final data = doc.data() as Map<String, dynamic>;

            final nombre = data['nombre'] ?? "Psicólogo";
            final especialidad = data['especialidad'] ?? "";
            final foto = data['foto'] ?? "";

            return Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: foto.isNotEmpty ? NetworkImage(foto) : null,
                  child: foto.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(nombre),
                subtitle: Text(especialidad),
                trailing: const Icon(Icons.calendar_today),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgendaScreen(
                        psicologoId: doc.id,
                        psicologoNombre: nombre,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
