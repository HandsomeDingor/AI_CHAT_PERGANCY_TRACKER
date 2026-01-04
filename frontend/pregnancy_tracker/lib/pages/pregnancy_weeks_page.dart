import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PregnancyWeeksPage extends StatefulWidget {
  const PregnancyWeeksPage({super.key});

  @override
  State<PregnancyWeeksPage> createState() => _PregnancyWeeksPageState();
}

class _PregnancyWeeksPageState extends State<PregnancyWeeksPage> {
  int _currentWeek = 1;
  bool _loading = false;

  static const pink = Color(0xFFF3A7BD);

  Future<void> _loadCurrentWeek() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();

      if (patientDoc.exists) {
        final patientData = patientDoc.data()!;
        final weeks = patientData['weeksOfPregnancy'] as int?;
        if (weeks != null) {
          setState(() {
            _currentWeek = weeks;
          });
        }
      }
    } catch (e) {
      print('Error loading current week: $e');
    }
  }

  Future<void> _updateWeek() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No user logged in';

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .update({
            'weeksOfPregnancy': _currentWeek,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated to Week $_currentWeek!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentWeek();
  }

  @override
  Widget build(BuildContext context) {
    final trimester = _currentWeek <= 13
        ? "First Trimester"
        : _currentWeek <= 26
            ? "Second Trimester"
            : "Third Trimester";

    final progress = _currentWeek / 40.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weeks of Pregnancy"),
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress Overview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Week $_currentWeek",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trimester,
                      style: TextStyle(
                        fontSize: 18,
                        color: pink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Progress Bar
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(pink),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Week 1",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Week 40",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Week Selector
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Update Current Week",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Week Display and Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentWeek > 1
                              ? () => setState(() => _currentWeek--)
                              : null,
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: pink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: pink),
                          ),
                          child: Text(
                            '$_currentWeek',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: _currentWeek < 40
                              ? () => setState(() => _currentWeek++)
                              : null,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Weeks",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pregnancy Milestones
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Week's Milestones",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMilestone(_currentWeek),
                  ],
                ),
              ),

              const Spacer(),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _updateWeek,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          "Update Pregnancy Week",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestone(int week) {
    final milestones = {
      8: "Baby's arms and legs are growing, major organs begin forming",
      12: "Risk of miscarriage decreases significantly, baby can make fists",
      16: "Baby can hear sounds, eyes are working and moving",
      20: "Halfway point! You might feel baby's movements",
      24: "Baby's skin becomes less transparent, practicing breathing",
      28: "Third trimester begins, baby can blink and dream",
      32: "Baby is gaining weight rapidly, less room to move",
      36: "Baby is considered full-term, lungs are mature",
      40: "Due date! Baby is ready to be born",
    };

    final milestoneWeek = milestones.keys
        .where((w) => w <= week)
        .toList()
        .lastOrNull;

    if (milestoneWeek != null) {
      return Text(
        milestones[milestoneWeek]!,
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue.shade700,
        ),
      );
    }

    return Text(
      "Early stages of pregnancy - baby's development is beginning",
      style: TextStyle(
        fontSize: 14,
        color: Colors.blue.shade700,
      ),
    );
  }
}