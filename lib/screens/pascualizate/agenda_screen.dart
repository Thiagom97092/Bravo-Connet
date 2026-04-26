import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/citas_service.dart';
import '../../services/firestore_service.dart';

class AgendaScreen extends StatefulWidget {
  final String psicologoId;
  final String psicologoNombre;

  const AgendaScreen({
    super.key,
    required this.psicologoId,
    required this.psicologoNombre,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final CitasService _service = CitasService();
  final FirestoreService _firestoreService = FirestoreService();

  final user = FirebaseAuth.instance.currentUser;

  String selectedDate = "";
  String selectedHora = "";
  String rol = "";
  String nombreUsuario = ""; // 🔥 NOMBRE REAL

  final List<String> horas = [
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // 🔥 CARGAR ROL + NOMBRE
  Future<void> loadUserData() async {
    final data = await _firestoreService.getUser(user!.uid);

    setState(() {
      rol = data?['rol'] ?? '';
      nombreUsuario = data?['nombre'] ?? 'Usuario';
    });
  }

  DateTime convertirFechaHora(String fecha, String hora) {
    final partesFecha = fecha.split('-');
    final partesHora = hora.split(':');

    return DateTime(
      int.parse(partesFecha[0]),
      int.parse(partesFecha[1]),
      int.parse(partesFecha[2]),
      int.parse(partesHora[0]),
      int.parse(partesHora[1]),
    );
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  Future<void> habilitarHorario() async {
    if (selectedDate.isEmpty || selectedHora.isEmpty) return;

    final fechaHora = convertirFechaHora(selectedDate, selectedHora);

    if (fechaHora.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No puedes habilitar horarios en el pasado")),
      );
      return;
    }

    final success = await _service.crearDisponibilidad(
      psicologoId: widget.psicologoId,
      psicologoNombre: widget.psicologoNombre,
      fecha: selectedDate,
      hora: selectedHora,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ese horario ya existe")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Horario habilitado: $selectedDate - $selectedHora"),
      ),
    );
  }

  // 🔥 RESERVAR CON NOMBRE REAL
  Future<void> reservarCita(String fecha, String hora) async {
    final success = await _service.crearCita(
      psicologoId: widget.psicologoId,
      psicologoNombre: widget.psicologoNombre,
      usuarioId: user!.uid,
      usuarioNombre: nombreUsuario, // 🔥 AQUÍ ESTÁ EL CAMBIO
      fecha: fecha,
      hora: hora,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Esta cita ya no está disponible")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Cita agendada: $fecha - $hora ✅")),
    );
  }

  Future<void> cancelarCita(String fecha, String hora) async {
    final success = await _service.cancelarCita(
      psicologoId: widget.psicologoId,
      fecha: fecha,
      hora: hora,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cita cancelada ❌")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esPsicologo = rol == "psicologo" || rol == "personal";
    final esEstudiante = rol == "estudiante";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.psicologoNombre),
      ),
      body: Column(
        children: [
          if (esPsicologo) ...[
            ElevatedButton(
              onPressed: pickDate,
              child: const Text("Seleccionar fecha"),
            ),
            if (selectedDate.isNotEmpty) Text("Fecha: $selectedDate"),
            DropdownButton<String>(
              hint: const Text("Seleccionar hora"),
              value: selectedHora.isEmpty ? null : selectedHora,
              items: horas.map((hora) {
                return DropdownMenuItem(
                  value: hora,
                  child: Text(hora),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedHora = value!;
                });
              },
            ),
            ElevatedButton(
              onPressed: habilitarHorario,
              child: const Text("Habilitar horario"),
            ),
            const Divider(),
          ],
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getAgendaPsicologo(widget.psicologoId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var citas = snapshot.data!.docs;
                final ahora = DateTime.now();

                final citasFiltradas = citas.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final estado = data['estado'];
                  final usuarioId = data['usuarioId'];
                  final fecha = data['fecha'];
                  final hora = data['hora'];

                  final fechaHora = convertirFechaHora(fecha, hora);

                  if (fechaHora.isBefore(ahora) && estado == 'disponible') {
                    return false;
                  }

                  if (esPsicologo) return true;

                  if (estado == 'disponible') return true;

                  if (estado == 'reservada' && usuarioId == user!.uid) {
                    return true;
                  }

                  return false;
                }).toList();

                return ListView.builder(
                  itemCount: citasFiltradas.length,
                  itemBuilder: (context, index) {
                    final data =
                        citasFiltradas[index].data() as Map<String, dynamic>;

                    final estado = data['estado'];
                    final fecha = data['fecha'];
                    final hora = data['hora'];
                    final usuario = data['usuarioNombre'];
                    final usuarioId = data['usuarioId'];

                    final fechaHora = convertirFechaHora(fecha, hora);
                    final yaPaso = fechaHora.isBefore(DateTime.now());

                    final esDisponible = estado == 'disponible';
                    final esMia = usuarioId == user!.uid;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text("$fecha - $hora"),
                        subtitle: Text(
                          yaPaso
                              ? "No disponible (hora pasada)"
                              : estado == 'reservada'
                                  ? esPsicologo
                                      ? "Reservada por: $usuario"
                                      : esMia
                                          ? "Tu cita"
                                          : ""
                                  : "Disponible",
                        ),
                        tileColor: yaPaso
                            ? Colors.grey[300]
                            : estado == 'reservada'
                                ? Colors.red[100]
                                : Colors.green[100],
                        onTap: (esEstudiante && esDisponible && !yaPaso)
                            ? () => reservarCita(fecha, hora)
                            : null,
                        trailing: (esEstudiante && esMia && !yaPaso)
                            ? IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () async {
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Cancelar cita"),
                                      content: const Text(
                                          "¿Seguro que deseas cancelar esta cita?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("No"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Sí"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    cancelarCita(fecha, hora);
                                  }
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
