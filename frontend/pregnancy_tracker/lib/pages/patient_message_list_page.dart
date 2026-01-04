import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_chat_page.dart';

class PatientMessageListPage extends StatefulWidget {
  const PatientMessageListPage({super.key});

  @override
  State<PatientMessageListPage> createState() => _PatientMessageListPageState();
}

class _PatientMessageListPageState extends State<PatientMessageListPage> {
  String? _currentPatientId;

  @override
  void initState() {
    super.initState();
    _getCurrentPatientId();
  }

  Future<void> _getCurrentPatientId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentPatientId = user.uid;
        });
        print('✅ Patient ID from Firebase Auth: ${user.uid}');
      } else {
        print('❌ No user logged in');
        setState(() {
          _currentPatientId = 'PATIENT_1';
        });
      }
    } catch (e) {
      print('Error getting patient ID: $e');
      setState(() {
        _currentPatientId = 'PATIENT_1';
      });
    }
  }

  Future<String> _ensureConversation({
    required String doctorId,
    required String patientId,
  }) async {
    final id = 'd_${doctorId}__p_${patientId}';
    final ref = FirebaseFirestore.instance.collection('conversations').doc(id);
    
    String patientName = 'Unknown Patient';
    try {
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();
          
      if (patientDoc.exists) {
        final data = patientDoc.data();
        final firstName = data?['firstName'] ?? '';
        final lastName = data?['lastName'] ?? '';
        patientName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();
        
        if (patientName.isEmpty) {
          patientName = data?['patientId']?.toString() ?? 'Unknown Patient';
        }
      }
    } catch (e) {
      print('Error getting patient name: $e');
    }

    await ref.set({
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'participants': [doctorId, patientId],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    }, SetOptions(merge: true));
    
    print('✅ Created conversation for patient: $patientName ($patientId)');
    return id;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPatientId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('🔍 Querying conversations for patient: $_currentPatientId');

    final q = FirebaseFirestore.instance
        .collection('conversations')
        .where('patientId', isEqualTo: _currentPatientId)
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
            print('❌ Stream error: ${snap.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snap.error}'),
                ],
              ),
            );
          }
          
          final docs = snap.data?.docs ?? [];
          print('📨 Found ${docs.length} conversations');
          
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No messages yet'),
                ],
              ),
            );
          }
          
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final d = docs[i].data();
              final doctorId = (d['doctorId'] ?? '').toString();
              final lastMessage = (d['lastMessage'] ?? '').toString();
              final conversationId = docs[i].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF80B8F0),
                  child: Text(
                    'DR',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                title: Text('Doctor $doctorId', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        conversationId: conversationId,
                        doctorId: doctorId,
                        patientId: _currentPatientId!,
                        peerName: 'Doctor $doctorId',
                        currentRole: 'patient',
                        currentUserId: _currentPatientId!,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_currentPatientId == null) return;
          
          print('🎯 Starting new conversation for patient: $_currentPatientId');
          
          final id = await _ensureConversation(
            doctorId: 'DOCTOR_1',
            patientId: _currentPatientId!,
          );
          
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  conversationId: id,
                  doctorId: 'DOCTOR_1',
                  patientId: _currentPatientId!,
                  peerName: 'Doctor DOCTOR_1',
                  currentRole: 'patient',
                  currentUserId: _currentPatientId!,
                ),
              ),
            );
          }
        },
        label: const Text('Message Doctor'),
        icon: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
