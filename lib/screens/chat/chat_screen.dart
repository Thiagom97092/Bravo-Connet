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

  final ImagePicker _picker = ImagePicker();

  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _chatService.markAsRead(widget.chatId);
    }
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

  // 🔥 CÁMARA
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

  // 🔥 GALERÍA
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

  // 🔥 ARCHIVO (CORREGIDO)
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();

    if (result != null && result.files.single.path != null) {
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

  Future<void> openFile(String url) async {
    final Uri uri = Uri.parse(url);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el archivo")),
      );
    }
  }

  Widget buildMessageContent(String type, Map<String, dynamic> data) {
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
              Expanded(
                child: Text(data['fileName'] ?? "Archivo"),
              ),
            ],
          ),
        );

      default:
        return Text(data['text'] ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text("No hay mensajes aún"),
                  );
                }

                messages.sort((a, b) {
                  final t1 = a['timestamp'];
                  final t2 = b['timestamp'];

                  if (t1 == null || t2 == null) return 0;
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == user!.uid;
                    final type = data['type'] ?? 'text';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: buildMessageContent(type, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
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
                  onPressed: () async {
                    if (_controller.text.trim().isEmpty) return;

                    await _chatService.sendMessage(
                      widget.chatId,
                      _controller.text.trim(),
                    );

                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
