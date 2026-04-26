import 'package:cloud_firestore/cloud_firestore.dart';

class CitasService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 Obtener psicólogos activos
  Stream<QuerySnapshot> getPsicologos() {
    return _db
        .collection('psicologos')
        .where('activo', isEqualTo: true)
        .snapshots();
  }

  // 🔥 MIGRACIÓN AUTOMÁTICA DE NOMBRES
  Future<void> migrarNombresUsuarios() async {
    try {
      final citasSnapshot = await _db.collection('citas').get();

      for (var doc in citasSnapshot.docs) {
        final data = doc.data();

        if (data['estado'] == 'reservada' && data['usuarioId'] != null) {
          final usuarioId = data['usuarioId'];

          final userDoc = await _db.collection('users').doc(usuarioId).get();

          if (userDoc.exists) {
            final nombreReal = userDoc.data()?['nombre'] ?? '';

            // 🔥 Solo actualizar si es diferente
            if (nombreReal.isNotEmpty && data['usuarioNombre'] != nombreReal) {
              await _db.collection('citas').doc(doc.id).update({
                'usuarioNombre': nombreReal,
              });

              print("Actualizado: ${doc.id}");
            }
          }
        }
      }

      print("🔥 Migración completada");
    } catch (e) {
      print("Error en migración: $e");
    }
  }

  // 🔥 HORAS OCUPADAS
  Future<List<String>> getHorasOcupadas(
    String psicologoId,
    String fecha,
  ) async {
    final snapshot = await _db
        .collection('citas')
        .where('psicologoId', isEqualTo: psicologoId)
        .where('fecha', isEqualTo: fecha)
        .where('estado', isEqualTo: 'reservada')
        .get();

    return snapshot.docs.map((doc) => doc['hora'] as String).toList();
  }

  // 🔥 HORAS DISPONIBLES
  Future<List<String>> getHorasDisponibles(
    String psicologoId,
    String fecha,
  ) async {
    final snapshot = await _db
        .collection('citas')
        .where('psicologoId', isEqualTo: psicologoId)
        .where('fecha', isEqualTo: fecha)
        .where('estado', isEqualTo: 'disponible')
        .get();

    return snapshot.docs.map((doc) => doc['hora'] as String).toList();
  }

  // 🔥 CREAR DISPONIBILIDAD
  Future<bool> crearDisponibilidad({
    required String psicologoId,
    required String psicologoNombre,
    required String fecha,
    required String hora,
  }) async {
    try {
      final query = await _db
          .collection('citas')
          .where('psicologoId', isEqualTo: psicologoId)
          .where('fecha', isEqualTo: fecha)
          .where('hora', isEqualTo: hora)
          .get();

      if (query.docs.isNotEmpty) return false;

      await _db.collection('citas').add({
        'psicologoId': psicologoId,
        'psicologoNombre': psicologoNombre,
        'fecha': fecha,
        'hora': hora,
        'estado': 'disponible',
        'usuarioId': null,
        'usuarioNombre': null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error crearDisponibilidad: $e");
      return false;
    }
  }

  // 🔥 RESERVAR CITA
  Future<bool> crearCita({
    required String psicologoId,
    required String psicologoNombre,
    required String usuarioId,
    required String usuarioNombre,
    required String fecha,
    required String hora,
  }) async {
    try {
      final query = await _db
          .collection('citas')
          .where('psicologoId', isEqualTo: psicologoId)
          .where('fecha', isEqualTo: fecha)
          .where('hora', isEqualTo: hora)
          .where('estado', isEqualTo: 'disponible')
          .get();

      if (query.docs.isEmpty) return false;

      final docId = query.docs.first.id;

      await _db.collection('citas').doc(docId).update({
        'estado': 'reservada',
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
      });

      return true;
    } catch (e) {
      print("Error crearCita: $e");
      return false;
    }
  }

  // 🔥 CANCELAR CITA
  Future<bool> cancelarCita({
    required String psicologoId,
    required String fecha,
    required String hora,
  }) async {
    try {
      final query = await _db
          .collection('citas')
          .where('psicologoId', isEqualTo: psicologoId)
          .where('fecha', isEqualTo: fecha)
          .where('hora', isEqualTo: hora)
          .where('estado', isEqualTo: 'reservada')
          .get();

      if (query.docs.isEmpty) return false;

      final docId = query.docs.first.id;

      await _db.collection('citas').doc(docId).update({
        'estado': 'disponible',
        'usuarioId': null,
        'usuarioNombre': null,
      });

      return true;
    } catch (e) {
      print("Error cancelarCita: $e");
      return false;
    }
  }

  // 🔥 AGENDA
  Stream<QuerySnapshot> getAgendaPsicologo(String psicologoId) {
    return _db
        .collection('citas')
        .where('psicologoId', isEqualTo: psicologoId)
        .snapshots();
  }
}
