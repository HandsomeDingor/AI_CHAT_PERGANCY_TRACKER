import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodPressureHistoryPage extends StatefulWidget {
  const BloodPressureHistoryPage({super.key});

  @override
  State<BloodPressureHistoryPage> createState() => _BloodPressureHistoryPageState();
}

class _BloodPressureHistoryPageState extends State<BloodPressureHistoryPage> {
  List<BloodPressureRecord> _records = [];
  bool _loading = true;
  String _filter = 'all';

  static const pink = Color(0xFFF3A7BD);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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

      if (patientId == null) {
        throw 'Patient ID not found';
      }

      print('Loading history for patient: $patientId');

      final query = await FirebaseFirestore.instance
          .collection('records')
          .orderBy('ts', descending: true)
          .get();

      final bpRecords = query.docs.where((doc) {
        final data = doc.data();
        return data['patient_id'] == patientId && data['type'] == 'blood_pressure';
      }).toList();

      print('Found ${bpRecords.length} BP records for patient $patientId');

      final records = bpRecords.map((doc) {
        final data = doc.data();
        return BloodPressureRecord(
          id: doc.id,
          systolic: data['systolic'] as int,
          diastolic: data['diastolic'] as int,
          timestamp: DateTime.parse(data['ts'] as String),
          week: data['week'] as int? ?? 0,
        );
      }).toList();

      setState(() => _records = records);
    } catch (e) {
      print('Error loading history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load history: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  List<BloodPressureRecord> get _filteredRecords {
    final now = DateTime.now();
    switch (_filter) {
      case 'week':
        return _records.where((record) {
          return now.difference(record.timestamp).inDays <= 7;
        }).toList();
      case 'month':
        return _records.where((record) {
          return now.difference(record.timestamp).inDays <= 30;
        }).toList();
      default:
        return _records;
    }
  }

  String _getStatus(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) {
      return 'High';
    } else if (systolic <= 90 || diastolic <= 60) {
      return 'Low';
    } else {
      return 'Normal';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: pink,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildRecordCard(BloodPressureRecord record) {
    final status = _getStatus(record.systolic, record.diastolic);
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${record.systolic}/${record.diastolic}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mmHg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Week ${record.week}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(record.timestamp),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(record.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure History'),
        backgroundColor: pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('This Week', 'week'),
                _buildFilterChip('This Month', 'month'),
              ],
            ),
          ),
          
          if (_filteredRecords.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${_filteredRecords.length} records found',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_filteredRecords.isNotEmpty)
                    FutureBuilder<Map<String, double>>(
                      future: _calculateAverages(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final averages = snapshot.data!;
                          return Text(
                            'Average: ${averages['systolic']?.toStringAsFixed(0)}/${averages['diastolic']?.toStringAsFixed(0)} mmHg',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                ],
              ),
            ),
          
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bloodtype_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No blood pressure records found',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start by recording your first measurement',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            return _buildRecordCard(_filteredRecords[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        backgroundColor: pink,
        foregroundColor: Colors.white,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  Future<Map<String, double>> _calculateAverages() async {
    if (_filteredRecords.isEmpty) return {'systolic': 0.0, 'diastolic': 0.0};
    
    final systolicSum = _filteredRecords.map((r) => r.systolic).reduce((a, b) => a + b);
    final diastolicSum = _filteredRecords.map((r) => r.diastolic).reduce((a, b) => a + b);
    
    return {
      'systolic': systolicSum / _filteredRecords.length,
      'diastolic': diastolicSum / _filteredRecords.length,
    };
  }
}

class BloodPressureRecord {
  final String id;
  final int systolic;
  final int diastolic;
  final DateTime timestamp;
  final int week;

  BloodPressureRecord({
    required this.id,
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
    required this.week,
  });
}
