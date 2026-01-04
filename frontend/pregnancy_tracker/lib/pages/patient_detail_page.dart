import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'patient_report_page.dart';
import 'message_chat_page.dart';

class PatientDetailPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientDetailPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  List<String> _categories = ['All', 'Blood Pressure', 'Blood Sugar', 'Medications', 'Mood', 'Food', 'Fetal Movements', 'Baby Kicks'];
  
  List<ReportEntry> _bpEntries = [];
  bool _loadingBpData = false;

  @override
  void initState() {
    super.initState();
    _loadBloodPressureData();
  }

  Future<void> _loadBloodPressureData() async {
    setState(() => _loadingBpData = true);
    try {
      final query = await _firestore
          .collection('records')
          .where('patient_id', isEqualTo: widget.patientId)
          .where('type', isEqualTo: 'blood_pressure')
          .get();

      final entries = query.docs.map((doc) {
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

      setState(() => _bpEntries = entries);
    } catch (e) {
      print('Error loading BP data: $e');
    } finally {
      setState(() => _loadingBpData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: const Color(0xFF80B8F0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: _openChat,
            tooltip: 'Send Message',
          ),
        ],
      ),
      body: Column(
        children: [
          // Blood Pressure Chart Section
          if (_bpEntries.isNotEmpty) _buildBloodPressureChart(),
          
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    isExpanded: true,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Blood Pressure Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    final patient = Patient(
                      name: widget.patientName, 
                      id: widget.patientId, 
                      insurance: 'Unknown'
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientReportPage(
                          patient: patient, 
                          entries: _bpEntries
                        ),
                      ),
                    );
                  },
                  child: const Text('View Full Report'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _loadingBpData 
                  ? const Center(child: CircularProgressIndicator())
                  : _bpEntries.isEmpty
                      ? const Center(child: Text('No blood pressure data'))
                      : BloodPressureMiniChart(entries: _bpEntries),
            ),
            const SizedBox(height: 8),
            const LegendRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getRecordsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading records',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final records = snapshot.data?.docs ?? [];
        
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No records found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'This patient has not recorded any health data yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index].data() as Map<String, dynamic>;
            return _buildRecordCard(record, index);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getRecordsStream() {
    if (_selectedCategory == 'All') {
      return _firestore
          .collection('records')
          .where('patient_id', isEqualTo: widget.patientId)
          .snapshots();
    } else {
      final type = _getRecordType(_selectedCategory);
      return _firestore
          .collection('records')
          .where('patient_id', isEqualTo: widget.patientId)
          .where('type', isEqualTo: type)
          .snapshots();
    }
  }

  String _getRecordType(String category) {
    switch (category) {
      case 'Blood Pressure': return 'blood_pressure';
      case 'Blood Sugar': return 'blood_sugar';
      case 'Medications': return 'medication';
      case 'Mood': return 'mood';
      case 'Food': return 'food';
      case 'Fetal Movements': return 'fetal_movements';
      case 'Baby Kicks': return 'baby_kicks';
      default: return '';
    }
  }

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    final type = record['type'] ?? '';
    final timestamp = record['ts'] != null 
        ? DateTime.parse(record['ts'] as String)
        : DateTime.now();
    final week = record['week'] ?? '';
    final fhirId = record['fhirObservationId'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getTypeDisplayName(type),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (fhirId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FHIR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRecordContent(record),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week $week',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordContent(Map<String, dynamic> record) {
    final type = record['type'] ?? '';
    
    switch (type) {
      case 'blood_pressure':
        return Text(
          '${record['systolic']}/${record['diastolic']} mmHg',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
        
      case 'blood_sugar':
        return Text(
          '${record['level']} mg/dL (${record['measurement_type']})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
        
      case 'medication':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record['medication_name']} - ${record['dosage']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Status: ${record['taken'] ? 'Taken' : 'Missed'}',
              style: TextStyle(
                color: record['taken'] ? Colors.green : Colors.red,
              ),
            ),
            if (record['notes'] != null && record['notes'].isNotEmpty)
              Text('Notes: ${record['notes']}'),
          ],
        );
        
      case 'mood':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood: ${record['mood']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (record['notes'] != null && record['notes'].isNotEmpty)
              Text('Notes: ${record['notes']}'),
          ],
        );
        
      case 'food':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${record['meal_type']}: ${record['food']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text('Rating: ${record['rating']}/5'),
                const SizedBox(width: 16),
                Text('Cravings: ${record['has_cravings'] ? 'Yes' : 'No'}'),
              ],
            ),
            if (record['notes'] != null && record['notes'].isNotEmpty)
              Text('Notes: ${record['notes']}'),
          ],
        );
        
      case 'fetal_movements':
        return Text(
          'Movements: ${record['count']}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
        
      case 'baby_kicks':
        return Text(
          'Kicks: ${record['kick_count']} (${record['session_duration']} min)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
        
      default:
        return Text(
          'Data: ${record.toString()}',
          style: const TextStyle(
            fontSize: 16,
          ),
        );
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'blood_pressure': return 'Blood Pressure';
      case 'blood_sugar': return 'Blood Sugar';
      case 'medication': return 'Medication';
      case 'mood': return 'Mood';
      case 'food': return 'Food Intake';
      case 'fetal_movements': return 'Fetal Movements';
      case 'baby_kicks': return 'Baby Kicks';
      default: return type;
    }
  }

  Future<void> _openChat() async {
    try {
      const doctorId = 'DOCTOR_1';
      final threadId = 'd_${doctorId}__p_${widget.patientId}';
      
      String patientName = widget.patientName;
      try {
        final patientDoc = await FirebaseFirestore.instance
            .collection('patients')
            .doc(widget.patientId)
            .get();
        if (patientDoc.exists) {
          final data = patientDoc.data();
          final firstName = data?['firstName'] ?? '';
          final lastName = data?['lastName'] ?? '';
          final realName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ').trim();
          if (realName.isNotEmpty) {
            patientName = realName;
          }
        }
      } catch (e) {
        print('Error getting patient name: $e');
      }
      
      final ref = FirebaseFirestore.instance.collection('conversations').doc(threadId);
      await ref.set({
        'doctorId': doctorId,
        'patientId': widget.patientId,
        'patientName': patientName,
        'participants': [doctorId, widget.patientId],
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            conversationId: threadId,
            doctorId: doctorId,
            patientId: widget.patientId,
            peerName: patientName,
            currentRole: 'doctor',
            currentUserId: doctorId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }
}

class BloodPressureMiniChart extends StatelessWidget {
  final List<ReportEntry> entries;

  const BloodPressureMiniChart({super.key, required this.entries});

  int _parseWeek(String label) {
    final m = RegExp(r'(\d+)').firstMatch(label);
    return m != null ? int.parse(m.group(1)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final data = [...entries]..sort((a, b) => _parseWeek(a.week).compareTo(_parseWeek(b.week)));
    final spotsSys = <FlSpot>[];
    final spotsDia = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spotsSys.add(FlSpot(i.toDouble(), data[i].systolic.toDouble()));
      spotsDia.add(FlSpot(i.toDouble(), data[i].diastolic.toDouble()));
    }

    final allY = [
      ...data.map((e) => e.systolic),
      ...data.map((e) => e.diastolic),
    ];
    final minY = (allY.reduce((a, b) => a < b ? a : b) - 10).toDouble();
    final maxY = (allY.reduce((a, b) => a > b ? a : b) + 10).toDouble();

    const systolicColor = Colors.blue;
    const diastolicColor = Colors.red;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 10,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[i].week.replaceAll('Week ', ''),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spotsSys,
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            color: systolicColor,
            isStrokeCapRound: true,
          ),
          LineChartBarData(
            spots: spotsDia,
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            color: diastolicColor,
            isStrokeCapRound: true,
          ),
        ],
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key});

  Widget _item(Color c, String label) => Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Row(
        children: [
          _item(Colors.blue, 'Systolic'),
          const SizedBox(width: 16),
          _item(Colors.red, 'Diastolic'),
        ],
      ),
    );
  }
}
