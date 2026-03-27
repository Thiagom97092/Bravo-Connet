import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // 🔥 STREAM GLOBAL DEL USUARIO
  Stream<DocumentSnapshot> getUserStream() {
    return _db.collection('users').doc(user!.uid).snapshots();
  }
}
