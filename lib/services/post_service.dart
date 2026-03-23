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
      'fecha': FieldValue.serverTimestamp(), // 🔥 MEJORADO
      'likes': [],
    });
  }

  // 🔥 OBTENER POSTS
  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ❤️ LIKE
  Future<void> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _db.collection('posts').doc(postId);

      DocumentSnapshot doc = await postRef.get();

      if (!doc.exists || doc.data() == null) return;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      List likes = data.containsKey('likes') ? data['likes'] : [];

      if (likes.contains(userId)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      print("Error en toggleLike: $e");
    }
  }

  // 💬 COMENTARIOS
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
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // 🗑 ELIMINAR
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }
}
