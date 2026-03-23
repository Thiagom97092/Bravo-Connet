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
    });

    return newChat.id;
  }

  // 📡 LISTA DE CHATS (SIN orderBy para evitar error)
  Stream<QuerySnapshot> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: user!.uid)
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

  // ✉️ ENVIAR MENSAJE
  Future<void> sendMessage(String chatId, String text) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': user!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }
}
