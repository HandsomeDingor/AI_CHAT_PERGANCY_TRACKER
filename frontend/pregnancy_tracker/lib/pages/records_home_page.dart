import 'package:flutter/material.dart';
import 'blood_pressure_page.dart';
import 'weight_page.dart';
import 'fetal_movements_page.dart';
import 'blood_sugar_page.dart';
import 'medications_page.dart';
import 'baby_kicks_page.dart';
import 'pregnancy_weeks_page.dart';
import 'mood_page.dart';
import 'food_tracking_page.dart';

class RecordsHomePage extends StatelessWidget {
  const RecordsHomePage({super.key});

  static const pink = Color(0xFFF3A7BD);

  Widget _menuButton(BuildContext context, String text, IconData icon, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 2,
            shadowColor: Colors.black12,
          ),
          onPressed: onTap,
          child: Row(
            children: [
              Icon(icon, color: pink, size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Pregnancy Records"),
        centerTitle: true,
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Track Your Pregnancy Health",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Record and monitor your health metrics",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                Expanded(
                  child: ListView(
                    children: [
                      _menuButton(
                        context,
                        "Blood Pressure",
                        Icons.monitor_heart_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BloodPressurePage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Today's Weight",
                        Icons.monitor_weight_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WeightPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Fetal Movements",
                        Icons.airline_seat_recline_normal_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FetalMovementsPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Blood Sugar",
                        Icons.bloodtype_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BloodSugarPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Medications",
                        Icons.medication_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MedicationsPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Baby Kicks",
                        Icons.favorite_border,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BabyKicksPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Weeks of Pregnancy",
                        Icons.calendar_today_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PregnancyWeeksPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Mood",
                        Icons.sentiment_satisfied_alt_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MoodPage()),
                          );
                        },
                      ),
                      _menuButton(
                        context,
                        "Track What I Eat",
                        Icons.restaurant_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FoodTrackingPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}