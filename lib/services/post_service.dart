import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 CREAR POST
  Future<void> createPost({
    required String uid,
    required String nombre,
    required String? fotoUsuario,
    required String contenido,
    String? imagenPost,
  }) async {
    await _db.collection('posts').add({
      'uid': uid,
      'nombre': nombre,
      'fotoUsuario': fotoUsuario ?? '',
      'contenido': contenido,
      'imagenPost': imagenPost ?? '',
      'fecha': DateTime.now(),
      'likes': [], // ❤️ siempre se crea
    });
  }

  // 🔥 OBTENER POSTS
  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ❤️ DAR / QUITAR LIKE (CORREGIDO)
  Future<void> toggleLike(String postId, String userId) async {
    DocumentReference postRef = _db.collection('posts').doc(postId);

    DocumentSnapshot doc = await postRef.get();

    // 🔥 Convertir a Map seguro
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 🔥 Validar si existe el campo 'likes'
    List likes = data.containsKey('likes') ? data['likes'] : [];

    if (likes.contains(userId)) {
      // ❌ quitar like
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      // ❤️ agregar like
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // 💬 AGREGAR COMENTARIO
  Future<void> addComment({
    required String postId,
    required String uid,
    required String nombre,
    required String comentario,
  }) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'uid': uid,
      'nombre': nombre,
      'comentario': comentario,
      'fecha': DateTime.now(),
    });
  }

  // 💬 OBTENER COMENTARIOS
  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('fecha', descending: true)
        .snapshots();
  }
}
