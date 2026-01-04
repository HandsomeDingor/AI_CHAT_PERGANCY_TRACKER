import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'message_chat_page.dart';

class DoctorMessageListPage extends StatelessWidget {
  const DoctorMessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('conversations')
        .where('doctorId', isEqualTo: 'DOCTOR_1')
        .orderBy('updatedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
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
                  Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              final conversationId = docs[i].id;
              final patientId = (d['patientId'] ?? '').toString();
              final lastMessage = (d['lastMessage'] ?? '').toString();
              final ts = d['updatedAt'];
              String timeText = '';
              if (ts is Timestamp) {
                final dt = ts.toDate();
                timeText =
                    '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('patients')
                    .doc(patientId)
                    .get(),
                builder: (context, patientSnap) {
                  String patientName = 'Unknown Patient';
                  String displayName = patientName;

                  if (patientSnap.connectionState == ConnectionState.done) {
                    if (patientSnap.hasData && patientSnap.data!.exists) {
                      final patientData = patientSnap.data!.data() as Map<String, dynamic>?;
                      if (patientData != null) {
                        final firstName = patientData['firstName'] ?? '';
                        final lastName = patientData['lastName'] ?? '';
                        patientName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();
                        if (patientName.isEmpty) {
                          patientName = patientData['patientId']?.toString() ?? 'Unknown Patient';
                        }
                      }
                    }
                    displayName = patientName;
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF80B8F0),
                      child: Text(
                        _getInitials(displayName),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lastMessage.isEmpty ? '(no messages yet)' : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: timeText.isEmpty ? null : Text(timeText, style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            conversationId: conversationId,
                            doctorId: 'DOCTOR_1',
                            patientId: patientId,
                            peerName: displayName,
                            currentRole: 'doctor',
                            currentUserId: 'DOCTOR_1',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
