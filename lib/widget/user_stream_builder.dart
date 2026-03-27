import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/user_provider.dart';

class UserStreamBuilder extends StatelessWidget {
  final Widget Function(Map<String, dynamic> userData) builder;

  const UserStreamBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider();

    return StreamBuilder<DocumentSnapshot>(
      stream: userProvider.getUserStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!.exists) {
          return const Center(child: Text("Usuario no encontrado"));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return builder(userData);
      },
    );
  }
}
