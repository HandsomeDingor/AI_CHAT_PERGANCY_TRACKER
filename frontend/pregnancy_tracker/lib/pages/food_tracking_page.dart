import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/fhir_provider.dart';

class FoodTrackingPage extends StatefulWidget {
  const FoodTrackingPage({super.key});

  @override
  State<FoodTrackingPage> createState() => _FoodTrackingPageState();
}

class _FoodTrackingPageState extends State<FoodTrackingPage> {
  final _foodController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _mealType = "Breakfast";
  int _rating = 3;
  bool _loading = false;
  bool _hasCravings = false;

  static const pink = Color(0xFFF3A7BD);
  final List<String> _mealTypes = [
    "Breakfast",
    "Morning Snack",
    "Lunch",
    "Afternoon Snack",
    "Dinner",
    "Evening Snack"
  ];

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

  Future<void> _saveFoodEntry() async {
    if (_foodController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what you ate')),
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
      final fhirPatientId = patientData['fhirPatientId'] ?? patientId;

      if (patientId == null) throw 'Patient ID not found';

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final fhirProvider = Provider.of<FhirProvider>(context, listen: false);
      Map<String, dynamic>? fhirResult;
      String? fhirObservationId;

      if (fhirProvider.syncEnabled && fhirProvider.isConnected) {
        fhirResult = await fhirProvider.syncFood(
          patientId: fhirPatientId,
          food: _foodController.text,
          mealType: _mealType,
          rating: _rating,
          hasCravings: _hasCravings,
          notes: _notesController.text,
          dateTime: dateTime,
          weekOfPregnancy: week,
        );

        if (fhirResult != null) {
          fhirObservationId = fhirResult['id'];
          print('✅ FHIR Food Observation created with ID: $fhirObservationId');
        }
      }

      final payload = {
        "patient_id": patientId,
        "type": "food",
        "food": _foodController.text,
        "meal_type": _mealType,
        "rating": _rating,
        "has_cravings": _hasCravings,
        "notes": _notesController.text,
        "week": week,
        "ts": dateTime.toUtc().toIso8601String(),
        "created_at": FieldValue.serverTimestamp(),
      };

      if (fhirObservationId != null) {
        payload['fhirObservationId'] = fhirObservationId;
        payload['fhirPatientId'] = fhirPatientId;
      }

      await FirebaseFirestore.instance.collection('records').add(payload);

      String message;
      if (fhirObservationId != null) {
        message = 'Food entry saved and synced to FHIR!';
      } else {
        message = 'Food entry saved successfully!';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      
      // Clear form
      _foodController.clear();
      _notesController.clear();
      setState(() {
        _rating = 3;
        _hasCravings = false;
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
        title: const Text("Track What I Eat"),
        backgroundColor: pink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Time",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Meal Type
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Meal Type",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mealTypes.map((type) {
                        final isSelected = type == _mealType;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _mealType = type;
                            });
                          },
                          selectedColor: pink,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Food Input
              TextField(
                controller: _foodController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "What did you eat?",
                  hintText: "Describe your meal or snack...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: pink, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rating
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How was it?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = rating;
                            });
                          },
                          child: Icon(
                            rating <= _rating ? Icons.star : Icons.star_border,
                            size: 40,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Didn't like"),
                        Text("Loved it!"),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cravings Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood, color: Colors.deepOrange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Was this a craving?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _hasCravings,
                      onChanged: (bool value) {
                        setState(() {
                          _hasCravings = value;
                        });
                      },
                      activeColor: pink,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Additional Notes (optional)",
                  hintText: "How did this food make you feel? Any reactions?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: pink, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveFoodEntry,
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
                          "Save Food Entry",
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

  @override
  void dispose() {
    _foodController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
