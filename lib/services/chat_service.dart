import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;

  String get _uid {
    if (user == null) {
      throw Exception("Usuario no autenticado");
    }
    return user!.uid;
  }

  // 🔥 CREAR O OBTENER CHAT
  Future<String> createOrGetChat(String otherUserId) async {
    final query = await _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .get();

    for (var doc in query.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await _db.collection('chats').add({
      'participants': [_uid, otherUserId],
      'lastMessage': '',
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {_uid: 0, otherUserId: 0},
    });

    return newChat.id;
  }

  // 🔥 LISTA DE CHATS
  Stream<QuerySnapshot> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _uid)
        .snapshots(); // ❌ quitamos orderBy para evitar índice
  }

  // 🔥 MENSAJES (SIN orderBy)
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots(); // ❌ quitamos orderBy
  }

  // 🔥 ENVIAR MENSAJE
  Future<void> sendMessage(
    String chatId,
    String text, [
    Map<String, dynamic>? extraData,
  ]) async {
    final chatRef = _db.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    final data = chatDoc.data()!;

    final participants = List<String>.from(data['participants']);
    final otherUser = participants.firstWhere((id) => id != _uid);

    final String type = extraData?['type'] ?? 'text';

    String lastMessageText = text;

    if (type == 'image') {
      lastMessageText = "📷 Imagen";
    } else if (type == 'file') {
      lastMessageText = "📎 Archivo";
    }

    await chatRef.collection('messages').add({
      'senderId': _uid,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      ...?extraData,
    });

    await chatRef.update({
      'lastMessage': lastMessageText,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'unreadCount.$otherUser': FieldValue.increment(1),
      'unreadCount.$_uid': 0,
    });
  }

  // 🔥 MARCAR COMO LEÍDO
  Future<void> markAsRead(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.$_uid': 0,
    });
  }
}
