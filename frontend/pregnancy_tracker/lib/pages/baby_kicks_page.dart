import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BabyKicksPage extends StatefulWidget {
  const BabyKicksPage({super.key});

  @override
  State<BabyKicksPage> createState() => _BabyKicksPageState();
}

class _BabyKicksPageState extends State<BabyKicksPage> {
  int _kickCount = 0;
  DateTime _sessionStart = DateTime.now();
  bool _sessionActive = false;
  bool _loading = false;
  final List<DateTime> _kickTimes = [];

  static const pink = Color(0xFFF3A7BD);

  void _startSession() {
    setState(() {
      _sessionActive = true;
      _sessionStart = DateTime.now();
      _kickCount = 0;
      _kickTimes.clear();
    });
  }

  void _recordKick() {
    if (!_sessionActive) return;
    
    setState(() {
      _kickCount++;
      _kickTimes.add(DateTime.now());
    });
  }

  void _stopSession() {
    setState(() {
      _sessionActive = false;
    });
  }

  Future<void> _saveSession() async {
    if (_kickCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record at least one kick')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No user logged in';

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();

      if (!patientDoc.exists) throw 'Patient information not found';

      final patientData = patientDoc.data()!;
      final patientId = patientData['patientId'];
      final week = patientData['weeksOfPregnancy'] ?? 0;

      if (patientId == null) throw 'Patient ID not found';

      final sessionEnd = DateTime.now();
      final duration = sessionEnd.difference(_sessionStart).inMinutes;

      final payload = {
        "patient_id": patientId,
        "type": "baby_kicks",
        "kick_count": _kickCount,
        "session_duration": duration,
        "week": week,
        "session_start": _sessionStart.toUtc().toIso8601String(),
        "session_end": sessionEnd.toUtc().toIso8601String(),
        "kick_times": _kickTimes.map((t) => t.toUtc().toIso8601String()).toList(),
        "created_at": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('records').add(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded $_kickCount kicks in $duration minutes!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getSessionDuration() {
    if (!_sessionActive) return "0 min";
    final duration = DateTime.now().difference(_sessionStart).inMinutes;
    return "$duration min";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Baby Kicks"),
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kick Counting Guide",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Start counting when baby is active\n• Count each distinct movement as one kick\n• Aim for 10 kicks within 2 hours\n• Contact your doctor if you notice decreased movement",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Session Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _sessionActive ? Colors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _sessionActive ? "Session Active" : "Session Not Started",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _sessionActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("Kicks", '$_kickCount'),
                        _buildStat("Duration", _getSessionDuration()),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Kick Counter
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                      "Baby Kicks",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_kickCount',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: FloatingActionButton(
                        onPressed: _sessionActive ? _recordKick : null,
                        backgroundColor: _sessionActive ? pink : Colors.grey,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.child_care, size: 40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sessionActive ? "Tap when baby kicks" : "Start session first",
                      style: TextStyle(
                        fontSize: 14,
                        color: _sessionActive ? Colors.grey : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Control Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sessionActive ? null : _startSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Start Session",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sessionActive ? _stopSession : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Stop Session",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_sessionActive || _kickCount == 0) ? null : _saveSession,
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
                          "Save Session",
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

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}