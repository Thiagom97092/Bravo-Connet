import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // 🔥 CREAR O BUSCAR CHAT
  Future<String> createOrGetChat(String otherUserId) async {
    final query = await _db
        .collection('chats')
        .where('participants', arrayContains: user!.uid)
        .get();

    for (var doc in query.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await _db.collection('chats').add({
      'participants': [user!.uid, otherUserId],
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {user!.uid: 0, otherUserId: 0},
    });

    return newChat.id;
  }

  // 🔥 LISTA DE CHATS
  Stream<QuerySnapshot> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: user!.uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  // 📡 MENSAJES
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // ✉️ ENVIAR MENSAJE (🔥 MEJORADO)
  Future<void> sendMessage(
    String chatId,
    String text, [
    Map<String, dynamic>? extraData,
  ]) async {
    final chatRef = _db.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    final data = chatDoc.data()!;

    final participants = List<String>.from(data['participants']);
    final otherUser = participants.firstWhere((id) => id != user!.uid);

    // 🔥 DEFINIR TIPO
    final String type = extraData?['type'] ?? 'text';

    // 🔥 MENSAJE PREVIEW (lo que se ve en lista de chats)
    String lastMessageText = text;

    if (type == 'image') {
      lastMessageText = "📷 Imagen";
    } else if (type == 'file') {
      lastMessageText = "📎 Archivo";
    }

    // 🔥 GUARDAR MENSAJE
    await chatRef.collection('messages').add({
      'senderId': user!.uid,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      ...?extraData, // 👈 AQUÍ SE GUARDAN fileUrl, fileName, etc
    });

    // 🔥 ACTUALIZAR CHAT
    await chatRef.update({
      'lastMessage': lastMessageText,
      'lastTimestamp': FieldValue.serverTimestamp(),

      // 🔴 MENSAJES NO LEÍDOS
      'unreadCount.$otherUser': FieldValue.increment(1),

      // 🟢 RESETEAR LOS MÍOS
      'unreadCount.${user!.uid}': 0,
    });
  }

  // ✅ MARCAR COMO LEÍDO
  Future<void> markAsRead(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.${user!.uid}': 0,
    });
  }
}
