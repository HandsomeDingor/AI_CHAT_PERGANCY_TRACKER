import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String doctorId;
  final String patientId;
  final String peerName;
  final String currentRole;
  final String currentUserId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.doctorId,
    required this.patientId,
    required this.peerName,
    required this.currentRole,
    required this.currentUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  CollectionReference<Map<String, dynamic>> get _msgCol => FirebaseFirestore
      .instance
      .collection('conversations')
      .doc(widget.conversationId)
      .collection('messages');

  bool _hasAccessToConversation() {
    if (widget.currentRole == 'doctor') {
      return widget.currentUserId == widget.doctorId;
    } else if (widget.currentRole == 'patient') {
      return widget.currentUserId == widget.patientId;
    }
    return false;
  }

  Future<void> _send() async {
    if (!_hasAccessToConversation()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access denied')),
      );
      return;
    }

    final text = _input.text.trim();
    if (text.isEmpty) return;

    final now = FieldValue.serverTimestamp();

    try {
      await _msgCol.add({
        'text': text,
        'senderId': widget.currentUserId,
        'senderRole': widget.currentRole,
        'createdAt': now,
      });

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .set({
            'doctorId': widget.doctorId,
            'patientId': widget.patientId,
            'patientName': widget.peerName,
            'lastMessage': text,
            'updatedAt': now,
          }, SetOptions(merge: true));

      _input.clear();

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccessToConversation()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to view this conversation'),
        ),
      );
    }

    final stream = _msgCol
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Say hi 👋'),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final d = docs[i].data();
                    final isMe = d['senderId'] == widget.currentUserId;
                    final text = (d['text'] ?? '').toString();

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF80B8F0) : Colors.white,
                          border: isMe ? null : Border.all(color: Colors.black12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
