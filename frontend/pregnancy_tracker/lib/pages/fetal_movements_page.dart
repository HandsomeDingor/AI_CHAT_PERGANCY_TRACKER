import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FetalMovementsPage extends StatefulWidget {
  const FetalMovementsPage({super.key});

  @override
  State<FetalMovementsPage> createState() => _FetalMovementsPageState();
}

class _FetalMovementsPageState extends State<FetalMovementsPage> {
  int _movementCount = 0;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = false;
  final List<DateTime> _movementTimes = [];

  static const pink = Color(0xFFF3A7BD);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _selectedDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _recordMovement() {
    setState(() {
      _movementCount++;
      _movementTimes.add(DateTime.now());
    });
  }

  Future<void> _saveMovements() async {
    if (_movementCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record at least one movement')),
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

      final payload = {
        "patient_id": patientId,
        "type": "fetal_movements",
        "count": _movementCount,
        "week": week,
        "session_start": DateTime.now().subtract(const Duration(minutes: 30)).toUtc().toIso8601String(),
        "session_end": DateTime.now().toUtc().toIso8601String(),
        "movement_times": _movementTimes.map((t) => t.toUtc().toIso8601String()).toList(),
        "created_at": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('records').add(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recorded $_movementCount movements!')),
      );
      
      // Reset counter
      setState(() {
        _movementCount = 0;
        _movementTimes.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fetal Movements"),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How to Count:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "• Sit comfortably and focus on baby's movements\n• Tap the button below each time you feel movement\n• Count for 30-60 minutes",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Movement Counter
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
                      "Movements Counted",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_movementCount',
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
                        onPressed: _recordMovement,
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.favorite, size: 40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tap when baby moves",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Session Info
              if (_movementTimes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Session Summary",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "• Total movements: $_movementCount\n• Session duration: ${_movementTimes.length > 1 ? _movementTimes.last.difference(_movementTimes.first).inMinutes : 0} minutes",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveMovements,
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
}