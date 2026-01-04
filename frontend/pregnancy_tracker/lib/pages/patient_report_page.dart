import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_chat_page.dart';

const String kDoctorId = 'DOCTOR_1';
String threadIdFor(String doctorId, String patientId) => 'd_${doctorId}__p_${patientId}';

class Patient {
  final String name;
  final String id;
  final String insurance;
  const Patient({required this.name, required this.id, required this.insurance});
}

class ReportEntry {
  final String week;
  final int systolic;
  final int diastolic;
  const ReportEntry({required this.week, required this.systolic, required this.diastolic});
}

class PatientReportPage extends StatelessWidget {
  const PatientReportPage({
    super.key,
    required this.patient,
    required this.entries,
  });

  final Patient patient;
  final List<ReportEntry> entries;

  static const blue = Color(0xFF80B8F0);

  Future<String> _ensureConversation({
    required String doctorId,
    required String patientId,
    required String patientName,
  }) async {
    final threadId = 'd_${doctorId}__p_${patientId}';
    final ref = FirebaseFirestore.instance.collection('conversations').doc(threadId);
    await ref.set({
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'participants': [doctorId, patientId],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    }, SetOptions(merge: true));

    return threadId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            _topPillButton(label: 'back', onTap: () => Navigator.pop(context)),
            const Spacer(),
            _topPillButton(
              label: 'next',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TODO: next patient')),
                );
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _infoLine('Patient Name', patient.name),
            _infoLine('ID', patient.id),
            _infoLine('Insurance', patient.insurance),
            const SizedBox(height: 8),
            _bpTable(entries),
            const SizedBox(height: 16),

            _BloodPressureSection(entries: entries),

            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  try {
                    final threadId = await _ensureConversation(
                      doctorId: kDoctorId,
                      patientId: patient.id,
                      patientName: patient.name,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          conversationId: threadId,
                          doctorId: kDoctorId,
                          patientId: patient.id,
                          peerName: patient.name,
                          currentRole: 'doctor',
                          currentUserId: kDoctorId,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to open chat: $e')),
                    );
                  }
                },
                child: const Text('Send message to patient'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topPillButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 34,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE8F2FF),
          foregroundColor: Colors.black87,
          shape: const StadiumBorder(side: BorderSide(color: Colors.black12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label :  ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _bpTable(List<ReportEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
        columns: const [
          DataColumn(label: Text('Pregnancy Week')),
          DataColumn(label: Text('systolic pressure (mmHg)')),
          DataColumn(label: Text('diastolic pressure (mmHg)')),
        ],
        rows: entries
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(e.week)),
                  DataCell(Text('${e.systolic}')),
                  DataCell(Text('${e.diastolic}')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BloodPressureSection extends StatelessWidget {
  final List<ReportEntry> entries;
  const _BloodPressureSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Blood Pressure Analysis Chart',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        SizedBox(height: 260, child: _BloodPressureChart(entries: entries)),
        const SizedBox(height: 8),
        const _LegendRow(),
      ],
    );
  }
}

class _BloodPressureChart extends StatelessWidget {
  final List<ReportEntry> entries;
  const _BloodPressureChart({required this.entries});

  int _parseWeek(String label) {
    final m = RegExp(r'(\d+)').firstMatch(label);
    return m != null ? int.parse(m.group(1)!) : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

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
          drawVerticalLine: true,
          getDrawingVerticalLine: (_) =>
              const FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [4, 4]),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Colors.black12, strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 10,
              getTitlesWidget: (v, meta) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 11)),
            ),
          ),
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
                  child: Text(data[i].week, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26)),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final label = s.barIndex == 0 ? 'Systolic' : 'Diastolic';
                return LineTooltipItem(
                  '${data[s.spotIndex].week}\n$label: ${s.y.toInt()}',
                  const TextStyle(fontWeight: FontWeight.w600),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spotsSys,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            color: systolicColor,
            isStrokeCapRound: true,
          ),
          LineChartBarData(
            spots: spotsDia,
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            color: diastolicColor,
            isStrokeCapRound: true,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

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
