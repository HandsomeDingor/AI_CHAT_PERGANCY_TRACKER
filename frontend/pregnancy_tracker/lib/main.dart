import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'auth_wrapper.dart';
import 'providers/fhir_provider.dart';

// Import all pages
import 'pages/doctor_main_page.dart';
import 'pages/patient_main_page.dart';
import 'pages/doctor_information_page.dart';
import 'pages/patient_information_page.dart';
import 'pages/patient_list_page.dart';
import 'pages/patient_report_page.dart';
import 'pages/records_home_page.dart';
import 'pages/blood_pressure_page.dart';
import 'pages/blood_pressure_record_page.dart';
import 'pages/blood_pressure_history_page.dart';
import 'pages/weight_page.dart';
import 'pages/blood_sugar_page.dart';
import 'pages/medications_page.dart';
import 'pages/fetal_movements_page.dart';
import 'pages/baby_kicks_page.dart';
import 'pages/pregnancy_weeks_page.dart';
import 'pages/mood_page.dart';
import 'pages/food_tracking_page.dart';
import 'pages/patient_detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PregnancyTrackerApp());
}

class PregnancyTrackerApp extends StatelessWidget {
  const PregnancyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FhirProvider()),
      ],
      child: MaterialApp(
        title: 'Pregnancy Tracker with FHIR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
        ),
        routes: {
          '/': (ctx) => const AuthWrapper(),
          '/patientMain': (ctx) => const PatientMainPage(),
          '/doctorMain': (ctx) => const DoctorMainPage(),
          '/doctorInfo': (ctx) => const DoctorInformationPage(),
          '/patientInfo': (ctx) => const PatientInformationPage(),
          '/records': (ctx) => const RecordsHomePage(),
          '/bloodPressure': (ctx) => const BloodPressurePage(),
          '/bloodPressureHistory': (ctx) => const BloodPressureHistoryPage(),
          '/weight': (ctx) => const WeightPage(),
          '/bloodSugar': (ctx) => const BloodSugarPage(),
          '/medications': (ctx) => const MedicationsPage(),
          '/fetalMovements': (ctx) => const FetalMovementsPage(),
          '/babyKicks': (ctx) => const BabyKicksPage(),
          '/pregnancyWeeks': (ctx) => const PregnancyWeeksPage(),
          '/mood': (ctx) => const MoodPage(),
          '/foodTracking': (ctx) => const FoodTrackingPage(),
          '/patientList': (ctx) => const PatientListPage(),
          '/home': (ctx) => const HomePage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/patientReport') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => PatientReportPage(
                patient: args['patient'],
                entries: args['entries'],
              ),
            );
          }
          
          if (settings.name == '/bloodPressureRecord') {
            final args = settings.arguments as DateTime?;
            return MaterialPageRoute(
              builder: (context) => BloodPressureRecordPage(
                initialDateTime: args ?? DateTime.now(),
              ),
            );
          }
          
          if (settings.name == '/patientDetail') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => PatientDetailPage(
                patientId: args['patientId']!,
                patientName: args['patientName']!,
              ),
            );
          }
          
          return null;
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      appBar: AppBar(
        title: const Text('Pregnancy Tracker with FHIR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.health_and_safety),
            onPressed: () {},
          ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Pregnancy Tracker',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Consumer<FhirProvider>(
              builder: (context, fhir, child) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: fhir.isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fhir.isConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            fhir.isConnected ? Icons.check_circle : Icons.warning,
                            color: fhir.isConnected ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fhir.isConnected ? 'FHIR Server Connected' : 'FHIR Server Not Connected',
                            style: TextStyle(
                              color: fhir.isConnected ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (!fhir.isConnected)
                      ElevatedButton(
                        onPressed: () => fhir.testConnection(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Test FHIR Connection'),
                      ),
                    if (fhir.lastError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error: ${fhir.lastError}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/patientMain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A6B6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Patient'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/doctorMain'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF80B8F0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Doctor'),
              ),
            ),
            
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text(
                  'Switch to Login',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
