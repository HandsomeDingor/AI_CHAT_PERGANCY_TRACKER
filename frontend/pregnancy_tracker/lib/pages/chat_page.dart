import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String sessionId;
  final String userId;
  const ChatPage({required this.sessionId, required this.userId, Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _ctrl = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> messagesRef() {
    return _db.collection('chats').doc(widget.sessionId).collection('messages');
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);

    await messagesRef().add({
      "role": "user",
      "text": text.trim(),
      "user_id": widget.userId,
      "ts": FieldValue.serverTimestamp(),
    });

    _ctrl.clear();

    final uri = Uri.parse("http://127.0.0.1:8000/api/chat");
    final resp = await http.post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "session_id": widget.sessionId,
          "user_id": widget.userId,
          "message": text.trim()
        }));

    if (resp.statusCode != 200) {
      await messagesRef().add({
        "role": "system",
        "text": "Assistant failed: ${resp.statusCode}",
        "user_id": "system",
        "ts": FieldValue.serverTimestamp(),
      });
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Assistant")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesRef().orderBy('ts', descending: false).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    final role = d['role'] ?? 'user';
                    final txt = d['text'] ?? '';
                    final align = role == 'user' ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                    final bg = role == 'user' ? Colors.blue[100] : Colors.grey[200];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: align,
                        children: [
                          Container(
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(10),
                            child: Text(txt),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: "Ask something...")),
                ),
                IconButton(
                  icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _sending ? null : () => sendMessage(_ctrl.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
