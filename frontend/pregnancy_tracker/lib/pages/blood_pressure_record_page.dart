import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/fhir_provider.dart';

class BloodPressureRecordPage extends StatefulWidget {
  final DateTime initialDateTime;
  const BloodPressureRecordPage({super.key, required this.initialDateTime});

  @override
  State<BloodPressureRecordPage> createState() => _BloodPressureRecordPageState();
}

class _BloodPressureRecordPageState extends State<BloodPressureRecordPage> {
  late DateTime _when;
  final _sysCtl = TextEditingController();
  final _diaCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  static const pink = Color(0xFFF3A7BD);

  @override
  void initState() {
    super.initState();
    _when = widget.initialDateTime;
  }

  @override
  void dispose() {
    _sysCtl.dispose();
    _diaCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(_when.year - 1),
      lastDate: DateTime(_when.year + 1),
      initialDate: _when,
    );
    if (picked != null) {
      setState(() => _when = DateTime(picked.year, picked.month, picked.day, _when.hour, _when.minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (picked != null) {
      setState(() => _when = DateTime(_when.year, _when.month, _when.day, picked.hour, picked.minute));
    }
  }

  Widget _chipButton(String text, VoidCallback onTap) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEDEDED),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _pinkAction(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _dateStr() =>
      "${_when.year}-${_when.month.toString().padLeft(2, '0')}-${_when.day.toString().padLeft(2, '0')}";
  String _timeStr(BuildContext ctx) => TimeOfDay.fromDateTime(_when).format(ctx);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final systolic = int.parse(_sysCtl.text);
    final diastolic = int.parse(_diaCtl.text);

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No user logged in';

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      
      if (!patientDoc.exists) {
        throw 'Patient information not found. Please complete your profile first.';
      }

      final patientData = patientDoc.data()!;
      final patientId = patientData['patientId'];
      final week = patientData['weeksOfPregnancy'] ?? 0;

      if (patientId == null) {
        throw 'Patient ID not found. Please complete your profile with Patient ID.';
      }

      final fhirProvider = Provider.of<FhirProvider>(context, listen: false);

      final fhirPatientId = patientData['fhirPatientId'] ?? patientId;
      
      Map<String, dynamic>? fhirResult;
      String? fhirObservationId;

      if (fhirProvider.syncEnabled && fhirProvider.isConnected) {
        fhirResult = await fhirProvider.syncBloodPressure(
          fhirPatientId: fhirPatientId,
          systolic: systolic,
          diastolic: diastolic,
          dateTime: _when,
          weekOfPregnancy: week,
        );

        if (fhirResult != null) {
          fhirObservationId = fhirResult['id'];
          print('✅ FHIR Observation created with ID: $fhirObservationId');
        }
      }

      final payload = <String, dynamic>{
        "patient_id": patientId,
        "type": "blood_pressure",
        "systolic": systolic,
        "diastolic": diastolic,
        "week": week,
        "ts": _when.toUtc().toIso8601String(),
        "created_at": FieldValue.serverTimestamp(),
      };

      if (fhirObservationId != null) {
        payload['fhirObservationId'] = fhirObservationId;
        payload['fhirPatientId'] = fhirPatientId;
      }

      final firestoreResult = await FirebaseFirestore.instance.collection('records').add(payload);

      if (fhirObservationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Blood pressure saved! Firebase ID: ${firestoreResult.id}, FHIR ID: $fhirObservationId")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Blood pressure saved to Firebase (FHIR sync disabled or failed)")),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createTestData() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No user logged in';

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      
      if (!patientDoc.exists) {
        throw 'Patient information not found';
      }

      final patientData = patientDoc.data()!;
      final patientId = patientData['patientId'];
      final baseWeek = patientData['weeksOfPregnancy'] ?? 28;

      if (patientId == null) {
        throw 'Patient ID not found';
      }

      final fhirProvider = Provider.of<FhirProvider>(context, listen: false);
      final fhirPatientId = patientData['fhirPatientId'] ?? patientId;
      
      final testRecords = [
        {
          "systolic": 110,
          "diastolic": 70,
          "week": baseWeek - 8,
          "ts": DateTime.now().subtract(const Duration(days: 56)).toUtc().toIso8601String(),
        },
        {
          "systolic": 112,
          "diastolic": 72,
          "week": baseWeek - 6,
          "ts": DateTime.now().subtract(const Duration(days: 42)).toUtc().toIso8601String(),
        },
        {
          "systolic": 115,
          "diastolic": 75,
          "week": baseWeek - 4,
          "ts": DateTime.now().subtract(const Duration(days: 28)).toUtc().toIso8601String(),
        },
      ];

      for (var record in testRecords) {
        Map<String, dynamic>? fhirResult;
        String? fhirObservationId;

        if (fhirProvider.syncEnabled && fhirProvider.isConnected) {
          fhirResult = await fhirProvider.syncBloodPressure(
            fhirPatientId: fhirPatientId,
            systolic: record["systolic"] as int,
            diastolic: record["diastolic"] as int,
            dateTime: DateTime.parse(record["ts"] as String),
            weekOfPregnancy: record["week"] as int,
          );

          if (fhirResult != null) {
            fhirObservationId = fhirResult['id'];
          }
        }

        final firestoreData = <String, dynamic>{
          "patient_id": patientId,
          "type": "blood_pressure",
          "systolic": record["systolic"],
          "diastolic": record["diastolic"],
          "week": record["week"],
          "ts": record["ts"],
          "created_at": FieldValue.serverTimestamp(),
        };

        if (fhirObservationId != null) {
          firestoreData['fhirObservationId'] = fhirObservationId;
          firestoreData['fhirPatientId'] = fhirPatientId;
        }

        await FirebaseFirestore.instance.collection('records').add(firestoreData);
        
        await Future.delayed(const Duration(milliseconds: 500));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Test data created successfully with FHIR IDs!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create test data: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle =
        TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600);

    return Consumer<FhirProvider>(
      builder: (context, fhir, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Blood Pressure Record")),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fhir.syncEnabled ? Colors.blue.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: fhir.syncEnabled ? Colors.blue : Colors.grey,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: fhir.syncEnabled ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fhir.syncEnabled 
                                ? 'FHIR Sync: Enabled'
                                : 'FHIR Sync: Disabled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: fhir.syncEnabled ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _chipButton(_dateStr(), _pickDate),
                      _chipButton(_timeStr(context), _pickTime),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Table(
                        columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
                        border: const TableBorder(
                          horizontalInside: BorderSide(color: Colors.black12),
                          verticalInside: BorderSide(color: Colors.black12),
                        ),
                        children: [
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("systolic pressure (mmHg)", style: headerStyle),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("diastolic pressure (mmHg)", style: headerStyle),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: _sysCtl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: "e.g. 110",
                                ),
                                validator: (v) {
                                  final n = int.tryParse(v ?? "");
                                  if (n == null || n < 50 || n > 250) return "50–250";
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextFormField(
                                controller: _diaCtl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: "e.g. 70",
                                ),
                                validator: (v) {
                                  final n = int.tryParse(v ?? "");
                                  if (n == null || n < 30 || n > 150) return "30–150";
                                  return null;
                                },
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (fhir.syncEnabled && !fhir.isConnected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'FHIR server not connected. Data will not be synced.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  if (_loading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text(
                            "Saving...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        _pinkAction("Save Blood Pressure", _save),
                        const SizedBox(height: 8),
                        _pinkAction("Create Test Data", _createTestData),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
