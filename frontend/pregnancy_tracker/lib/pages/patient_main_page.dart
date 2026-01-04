import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pregnancy_tracker/pages/chat_page.dart';
import 'patient_message_list_page.dart';

class PatientMainPage extends StatelessWidget {
  const PatientMainPage({super.key});

  static const Color kRose = Color(0xFFE8A6B6);
  static const Color kPageBg = Color(0xFFFFF7F9);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPageBg,
      appBar: AppBar(
        title: const Text('Pregnancy Tracker'),
        centerTitle: true,
        backgroundColor: kRose,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Header image (Patient)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/patient_header.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('patient_header.png not found'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.12), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _bigButton(
              label: 'Record the Pregnancy Health',
              onTap: () => Navigator.pushNamed(context, '/records'),
            ),
            const SizedBox(height: 12),

            _bigButton(
              label: 'AI Assistant Chat',
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                String uid;
                if (user != null && user.uid.isNotEmpty) {
                  uid = user.uid;
                } else {
                  uid = 'anon_${DateTime.now().millisecondsSinceEpoch}';
                }

                final sessionId = 'user_$uid'; 

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(sessionId: sessionId, userId: uid),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _bigButton(
              label: 'My Doctor',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TODO: My Doctor')),
                );
              },
            ),
            const SizedBox(height: 12),

            _bigButton(
              label: 'Messages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientMessageListPage()),
                );
              },
            ),
            const SizedBox(height: 12),

            _bigButton(
              label: 'My Information',
              onTap: () => Navigator.pushNamed(context, '/patientInfo'),
            ),
          ],
        ),
      ),
    );
  }

  /// Unified style big button
  Widget _bigButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kRose,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
