import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final user = FirebaseAuth.instance.currentUser;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.chatId);
  }

  // 🔥 STREAM GLOBAL DEL USUARIO
  Stream<DocumentSnapshot> getUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots();
  }

  // 🔥 SUBIR IMAGEN
  Future<String> uploadImage(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
          'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 🔥 SUBIR ARCHIVO
  Future<String> uploadFile(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
          'chat_files/${DateTime.now().millisecondsSinceEpoch}',
        );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 📷 CÁMARA
  Future<void> pickFromCamera() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      final url = await uploadImage(File(picked.path));

      await _chatService.sendMessage(widget.chatId, "", {
        'type': 'image',
        'fileUrl': url,
      });
    }
  }

  // 🖼 GALERÍA
  Future<void> pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final url = await uploadImage(File(picked.path));

      await _chatService.sendMessage(widget.chatId, "", {
        'type': 'image',
        'fileUrl': url,
      });
    }
  }

  // 📎 ARCHIVOS
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      final url = await uploadFile(file);

      await _chatService.sendMessage(widget.chatId, "", {
        'type': 'file',
        'fileUrl': url,
        'fileName': result.files.single.name,
      });
    }
  }

  void showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Tomar foto"),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Elegir imagen"),
              onTap: () {
                Navigator.pop(context);
                pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text("Enviar archivo"),
              onTap: () {
                Navigator.pop(context);
                pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 ENVÍO CON DATOS ACTUALIZADOS
  Future<void> sendMessage(Map<String, dynamic> userData) async {
    if (_controller.text.trim().isEmpty) return;

    await _chatService.sendMessage(
      widget.chatId,
      _controller.text.trim(),
      {
        'nombre': userData['nombre'],
        'foto': userData['foto'],
      },
    );

    _controller.clear();
  }

  // 🔥 ABRIR ARCHIVO
  Future<void> openFile(String url) async {
    final Uri uri = Uri.parse(url);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el archivo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: getUserStream(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(title: const Text("Chat")),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data =
                            messages[index].data() as Map<String, dynamic>;

                        final isMe = data['senderId'] == user!.uid;
                        final type = data['type'] ?? 'text';

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: buildMessageContent(type, data, isMe),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // INPUT
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: showOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Escribe un mensaje...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => sendMessage(userData),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildMessageContent(
      String type, Map<String, dynamic> data, bool isMe) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => openFile(data['fileUrl']),
          child: Image.network(data['fileUrl'], height: 200),
        );

      case 'file':
        return GestureDetector(
          onTap: () => openFile(data['fileUrl']),
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file),
              const SizedBox(width: 8),
              Text(data['fileName'] ?? "Archivo"),
            ],
          ),
        );

      default:
        return Text(data['text'] ?? '');
    }
  }
}
