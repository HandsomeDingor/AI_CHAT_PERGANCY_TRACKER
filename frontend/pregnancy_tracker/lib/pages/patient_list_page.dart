import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_report_page.dart';
import 'patient_detail_page.dart';

class PatientListPage extends StatefulWidget {
  const PatientListPage({super.key});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  static const Color kBlue = Color(0xFF89AEE6);
  static const Color kBg = Color(0xFFF7FAFF);

  final TextEditingController _search = TextEditingController();
  String _keyword = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _checkFirestoreConnection();
  }

  Future<void> _checkFirestoreConnection() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .limit(1)
          .get();
      print('✅ Firestore connection successful. Collection exists.');
    } catch (e) {
      print('❌ Firestore connection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Patients'),
        centerTitle: true,
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                _filters(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading patients...'),
                      ],
                    ),
                  );
                }

                if (snap.hasError) {
                  print('❌ Firestore Error: ${snap.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading patients',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snap.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                
                print('=== DEBUG: Found ${docs.length} documents in patients collection ===');
                for (var doc in docs) {
                  final data = doc.data();
                  print('📄 Document ID: ${doc.id}');
                  print('   - Patient ID: ${data['patientId'] ?? "NULL"}');
                  print('   - Name: ${data['firstName'] ?? "NULL"} ${data['lastName'] ?? "NULL"}');
                  print('   - Weeks: ${data['weeksOfPregnancy'] ?? "NULL"}');
                  print('   - Insurance: ${data['insuranceCompany'] ?? "NULL"}');
                  print('   - Updated: ${data['updatedAt'] ?? "NULL"}');
                  print('   - Has FHIR ID: ${data['fhirPatientId'] != null}');
                  print('   ---');
                }

                final validPatients = docs.where((doc) {
                  final data = doc.data();
                  final hasPatientId = data['patientId'] != null && 
                                      data['patientId'].toString().isNotEmpty;
                  final hasName = (data['firstName'] != null && data['firstName'].toString().isNotEmpty) ||
                                 (data['lastName'] != null && data['lastName'].toString().isNotEmpty);
                  
                  final isValid = hasPatientId && hasName;
                  if (!isValid) {
                    print('⚠️ Filtering out invalid patient: ${doc.id}');
                  }
                  return isValid;
                }).toList();

                print('✅ Valid patients after filtering: ${validPatients.length}');

                if (validPatients.isEmpty) {
                  return _buildEmptyState(docs.isNotEmpty);
                }

                final all = validPatients.map((d) => _Patient.fromDoc(d)).toList();
                Iterable<_Patient> list = all.where((p) {
                  if (_keyword.isEmpty) return true;
                  final kw = _keyword.toLowerCase();
                  return p.name.toLowerCase().contains(kw) ||
                      p.id.toLowerCase().contains(kw) ||
                      p.insurer.toLowerCase().contains(kw);
                });

                switch (_filter) {
                  case 'High Risk':
                    list = list.where((p) => p.isHighRisk);
                    break;
                  case 'Recent':
                    list = list.where((p) => p.isRecent24h);
                    break;
                  default:
                    break;
                }

                final data = list.toList();
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No patients match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _patientTile(context, data[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _createTestPatient,
            backgroundColor: Colors.orange,
            mini: true,
            tooltip: 'Create Test Patients',
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing...')),
              );
            },
            backgroundColor: kBlue,
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: (v) => setState(() => _keyword = v.trim()),
      decoration: InputDecoration(
        hintText: 'Search name / ID / insurer',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF3F6FB),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filters() {
    return Row(
      children: [
        _pill('All'),
        const SizedBox(width: 8),
        _pill('High Risk', color: const Color(0xFFFF8C8C)),
        const SizedBox(width: 8),
        _pill('Recent'),
      ],
    );
  }

  Widget _pill(String label, {Color? color}) {
    final selected = _filter == label;
    final bg = selected ? (color ?? kBlue) : const Color(0xFFF3F6FB);
    final fg = selected ? Colors.white : const Color(0xFF4E5969);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  Widget _patientTile(BuildContext context, _Patient p) {
    final Color chipBg;
    final Color chipFg;
    if (p.isHighRisk) {
      chipBg = const Color(0xFFFFEFEF);
      chipFg = const Color(0xFFE05B5B);
    } else {
      chipBg = const Color(0xFFEFF6FF);
      chipFg = const Color(0xFF2B6CB0);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _showPatientOptions(context, p);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kBlue,
                child: Text(
                  _initials(p.name),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name.isEmpty ? '(No name)' : p.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${p.id} • ${p.insurer}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Week ${p.weekDisplay} • ${p.recentDisplay}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.riskLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: chipFg),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientOptions(BuildContext context, _Patient p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View ${p.name}'),
        content: const Text('Choose what to view:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openBloodPressureReport(context, p);
            },
            child: const Text('Blood Pressure Report'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openFullHealthRecords(context, p);
            },
            child: const Text('All Health Records'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBloodPressureReport(BuildContext context, _Patient p) async {
    try {
      final entries = await _loadBpEntries(p.id);
      final patient = Patient(name: p.name, id: p.id, insurance: p.insurer);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientReportPage(patient: patient, entries: entries),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load blood pressure data: $e')),
      );
    }
  }

  void _openFullHealthRecords(BuildContext context, _Patient p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailPage(
          patientId: p.id,
          patientName: p.name,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasInvalidData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            hasInvalidData ? 'No Valid Patients' : 'No Patients Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hasInvalidData
                  ? 'Patients need to complete their profile with:\n• Patient ID\n• First and Last Name'
                  : 'Patients will appear here once they register and complete their profile information.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createTestPatient,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Test Patients'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestPatient() async {
    try {
      final testPatients = [
        {
          'patientId': 'TEST001',
          'firstName': 'Alice',
          'lastName': 'Smith',
          'phone': '555-0101',
          'email': 'alice@example.com',
          'insuranceCompany': 'HealthPlus',
          'insuranceId': 'HP12345',
          'weight': 65.5,
          'weeksOfPregnancy': 28,
          'fhirPatientId': 'test-fhir-id-001',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'patientId': 'TEST002', 
          'firstName': 'Bob',
          'lastName': 'Johnson',
          'phone': '555-0102',
          'email': 'bob@example.com',
          'insuranceCompany': 'CareFirst',
          'insuranceId': 'CF67890',
          'weight': 70.2,
          'weeksOfPregnancy': 32,
          'risk': 'High Risk',
          'fhirPatientId': 'test-fhir-id-002',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'patientId': 'TEST003',
          'firstName': 'Carol',
          'lastName': 'Williams',
          'phone': '555-0103',
          'email': 'carol@example.com',
          'insuranceCompany': 'MediCare',
          'insuranceId': 'MC11111',
          'weight': 68.0,
          'weeksOfPregnancy': 24,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var patientData in testPatients) {
        final patientId = patientData['patientId'] as String;
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .set(patientData, SetOptions(merge: true));
        
        print('✅ Created test patient: $patientId');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test patients created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Failed to create test patients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test patients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<ReportEntry> _mockEntries() {
    return const [
      ReportEntry(week: 'Week 28', systolic: 111, diastolic: 30),
      ReportEntry(week: 'Week 20', systolic: 118, diastolic: 74),
      ReportEntry(week: 'Week 12', systolic: 110, diastolic: 70),
    ];
  }

  Future<List<ReportEntry>> _loadBpEntries(String patientId) async {
    try {
      print('=== DEBUG: Loading BP records for patient: $patientId ===');

      final query = await FirebaseFirestore.instance
          .collection('records')
          .orderBy('ts', descending: true)
          .get();

      print('Total records in collection: ${query.docs.length}');

      final bpRecords = query.docs.where((doc) {
        final data = doc.data();
        final isBloodPressure = data['type'] == 'blood_pressure';
        final isPatientMatch = data['patient_id'] == patientId;
        
        if (isBloodPressure && isPatientMatch) {
          print('Found BP record: ${doc.id}');
          print('  - systolic: ${data['systolic']}, diastolic: ${data['diastolic']}');
          print('  - week: ${data['week']}');
          return true;
        }
        return false;
      }).toList();

      print('Filtered BP records for patient $patientId: ${bpRecords.length}');

      if (bpRecords.isEmpty) {
        print('No BP records found, showing sample data');
        return _createSampleData(patientId);
      }

      final entries = bpRecords.map((doc) {
        final data = doc.data();
        final week = data['week'] as int? ?? 0;
        final sys = data['systolic'] as int;
        final dia = data['diastolic'] as int;
        return ReportEntry(week: 'Week $week', systolic: sys, diastolic: dia);
      }).toList();

      entries.sort((a, b) {
        final weekA = int.parse(a.week.replaceAll('Week ', ''));
        final weekB = int.parse(b.week.replaceAll('Week ', ''));
        return weekA.compareTo(weekB);
      });

      return entries;

    } catch (e) {
      print('Error loading BP entries: $e');
      return _createSampleData(patientId);
    }
  }

  List<ReportEntry> _createSampleData(String patientId) {
    print('Creating sample data for patient: $patientId');
    return const [
      ReportEntry(week: 'Week 25', systolic: 115, diastolic: 75),
      ReportEntry(week: 'Week 26', systolic: 118, diastolic: 78),
      ReportEntry(week: 'Week 27', systolic: 120, diastolic: 80),
      ReportEntry(week: 'Week 28', systolic: 122, diastolic: 82),
    ];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _Patient {
  final String firestoreDocId;
  final String id;
  final String name;
  final String insurer;
  final int? weeksOfPregnancy;
  final String? risk;
  final Timestamp? updatedAt;

  _Patient({
    required this.firestoreDocId,
    required this.id,
    required this.name,
    required this.insurer,
    required this.weeksOfPregnancy,
    required this.risk,
    required this.updatedAt,
  });

  factory _Patient.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final first = (d['firstName'] ?? '').toString().trim();
    final last = (d['lastName'] ?? '').toString().trim();
    
    final patientId = (d['patientId'] ?? doc.id).toString();
    
    return _Patient(
      firestoreDocId: doc.id,
      id: patientId,
      name: [first, last].where((e) => e.isNotEmpty).join(' ').trim(),
      insurer: (d['insuranceCompany'] ?? '').toString(),
      weeksOfPregnancy: (d['weeksOfPregnancy'] is int)
          ? d['weeksOfPregnancy'] as int
          : int.tryParse('${d['weeksOfPregnancy'] ?? ''}'),
      risk: (d['risk'] ?? '').toString(),
      updatedAt: d['updatedAt'] is Timestamp ? d['updatedAt'] as Timestamp : null,
    );
  }

  bool get isHighRisk => (risk ?? '').toLowerCase().contains('high');

  bool get isRecent24h {
    if (updatedAt == null) return false;
    final dt = updatedAt!.toDate();
    return DateTime.now().difference(dt).inHours < 24;
  }

  String get weekDisplay => weeksOfPregnancy?.toString() ?? '-';

  String get riskLabel => (risk == null || risk!.trim().isEmpty) ? 'Normal' : risk!;

  String get recentDisplay {
    if (updatedAt == null) return 'Updated -';
    final dt = updatedAt!.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}
