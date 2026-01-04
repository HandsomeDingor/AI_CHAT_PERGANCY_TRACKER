import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'pages/patient_main_page.dart';
import 'pages/doctor_main_page.dart';
import 'pages/patient_information_page.dart';
import 'pages/doctor_information_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        final user = snapshot.data;
        
        if (user == null) {
          return const LoginPage();
        }
        
        return const UserTypeRouter();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety,
              size: 80,
              color: Color(0xFFF3A7BD),
            ),
            const SizedBox(height: 20),
            Text(
              'Pregnancy Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class UserTypeRouter extends StatefulWidget {
  const UserTypeRouter({super.key});

  @override
  State<UserTypeRouter> createState() => _UserTypeRouterState();
}

class _UserTypeRouterState extends State<UserTypeRouter> {
  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    if (uid == null) {
      return;
    }

    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();

      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data();
        final hasBasicInfo = doctorData?['firstName'] != null && 
                            doctorData?['firstName'].toString().isNotEmpty == true;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasBasicInfo) {
            Navigator.pushReplacementNamed(context, '/doctorMain');
          } else {
            Navigator.pushReplacementNamed(context, '/doctorInfo');
          }
        });
        return;
      }

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();

      if (patientDoc.exists) {
        final patientData = patientDoc.data();
        final hasBasicInfo = patientData?['patientId'] != null && 
                            patientData?['patientId'].toString().isNotEmpty == true;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasBasicInfo) {
            Navigator.pushReplacementNamed(context, '/patientMain');
          } else {
            Navigator.pushReplacementNamed(context, '/patientInfo');
          }
        });
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseAuth.instance.signOut();
      });

    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/patientMain');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}