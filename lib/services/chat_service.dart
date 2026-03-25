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

  // 🔥 ORDENADO POR MÁS RECIENTE
  Stream<QuerySnapshot> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: user!.uid)
        .orderBy('lastTimestamp', descending: true) // 🔥 CLAVE
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
    final chatRef = _db.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();
    final data = chatDoc.data()!;

    final participants = List<String>.from(data['participants']);

    final otherUser = participants.firstWhere((id) => id != user!.uid);

    await chatRef.collection('messages').add({
      'senderId': user!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),

      // 🔴 SUMA NO LEÍDOS AL OTRO
      'unreadCount.$otherUser': FieldValue.increment(1),

      // 🟢 RESETEA LOS MÍOS
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
