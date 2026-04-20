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

  Future<String> uploadImage(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
          'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadFile(File file) async {
    final ref = FirebaseStorage.instance.ref().child(
          'chat_files/${DateTime.now().millisecondsSinceEpoch}',
        );
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

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
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
              Expanded(child: Text(data['fileName'] ?? "Archivo")),
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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(title: const Text("Chat"), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                messages.sort((a, b) {
                  final t1 = a['timestamp'];
                  final t2 = b['timestamp'];
                  if (t1 == null || t2 == null) return 0;
                  return t2.compareTo(t1);
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;

                    final isMe = data['senderId'] == user!.uid;
                    final type = data['type'] ?? 'text';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green.shade600 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                          child: buildMessageContent(type, data),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: showOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () async {
                        if (_controller.text.trim().isEmpty) return;

                        await _chatService.sendMessage(
                          widget.chatId,
                          _controller.text.trim(),
                        );

                        _controller.clear();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
