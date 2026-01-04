import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/fhir_provider.dart';
import '../services/fhir_service.dart';

class PatientInformationPage extends StatefulWidget {
  const PatientInformationPage({super.key});

  @override
  State<PatientInformationPage> createState() => _PatientInformationPageState();
}

class _PatientInformationPageState extends State<PatientInformationPage> {
  final _patientId = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _phone     = TextEditingController();
  final _insuranceCompany = TextEditingController();
  final _insuranceId = TextEditingController();
  final _email     = TextEditingController();
  final _weight    = TextEditingController();
  final _weeks     = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isNewPatient = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No UID';
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      final d = doc.data();
      if (d != null) {
        _patientId.text = d['patientId'] ?? '';
        _firstName.text = d['firstName'] ?? '';
        _lastName.text  = d['lastName'] ?? '';
        _phone.text     = d['phone'] ?? '';
        _insuranceCompany.text = d['insuranceCompany'] ?? '';
        _insuranceId.text = d['insuranceId'] ?? '';
        _email.text     = d['email'] ?? '';
        _weight.text    = (d['weight']?.toString() ?? '');
        _weeks.text     = (d['weeksOfPregnancy']?.toString() ?? '');
        
        if (_patientId.text.isNotEmpty) {
          _isNewPatient = false;
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    
    if (_patientId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Patient ID')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No UID';

      final patientId = _patientId.text.trim();
      final firstName = _firstName.text.trim();
      final lastName = _lastName.text.trim();
      final phone = _phone.text.trim();
      final email = _email.text.trim();
      final weight = double.tryParse(_weight.text.trim()) ?? 0;
      final weeks = int.tryParse(_weeks.text.trim()) ?? 0;

      String? fhirPatientId;

      final fhirProvider = Provider.of<FhirProvider>(context, listen: false);
      final existingPatientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();
      
      final existingFhirPatientId = existingPatientDoc.data()?['fhirPatientId'];
      
      Map<String, dynamic>? fhirResult;
      
      if (existingFhirPatientId != null) {
        print('🔄 Updating existing FHIR Patient: $existingFhirPatientId');
        final patientResource = FhirService.createPatientResource(
          id: patientId,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          weeksOfPregnancy: weeks,
          weight: weight,
        );
        
        patientResource['id'] = existingFhirPatientId;
        
        fhirResult = await FhirService.updateResource(patientResource);
        fhirPatientId = existingFhirPatientId;
      } else {
        print('🆕 Creating new FHIR Patient');
        final patientResource = FhirService.createPatientResource(
          id: patientId,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          weeksOfPregnancy: weeks,
          weight: weight,
        );

        fhirResult = await FhirService.saveResource(patientResource);
        if (fhirResult != null) {
          fhirPatientId = fhirResult['id'];
        }
      }

      final data = {
        'patientId': patientId,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'insuranceCompany': _insuranceCompany.text.trim(),
        'insuranceId': _insuranceId.text.trim(),
        'email': email,
        'weight': weight,
        'weeksOfPregnancy': weeks,
        'fhirPatientId': fhirPatientId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      String message;
      if (fhirResult != null) {
        message = existingFhirPatientId != null 
            ? 'Patient information updated in Firestore and FHIR!'
            : 'Patient information saved to Firestore and FHIR! FHIR ID: $fhirPatientId';
      } else {
        message = 'Saved to Firestore (FHIR sync failed)';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/patientMain');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _patientId.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _insuranceCompany.dispose();
    _insuranceId.dispose();
    _email.dispose();
    _weight.dispose();
    _weeks.dispose();
    super.dispose();
  }

  Widget _input(String label, TextEditingController c, {TextInputType? type, bool? enabled}) {
    return TextFormField(
      controller: c, 
      keyboardType: type,
      enabled: enabled ?? true,
      decoration: InputDecoration(
        labelText: label,
        filled: true, 
        fillColor: const Color(0xFFFFF7F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const rose = Color(0xFFE8A6B6);
    
    return Consumer<FhirProvider>(
      builder: (context, fhir, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Basic Information'),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'logout') {
                    try {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logout failed: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Please enter your information.',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    
                    // FHIR Sync Status
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FHIR Integration',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: fhir.syncEnabled ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                Text(
                                  fhir.syncEnabled 
                                      ? 'Data will be synced with FHIR server'
                                      : 'FHIR sync is disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: fhir.syncEnabled ? Colors.blue : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: fhir.syncEnabled,
                            onChanged: (value) => fhir.toggleSync(value),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _input('Patient ID', _patientId, 
                      type: TextInputType.text,
                      enabled: _isNewPatient,
                    ),
                    if (!_isNewPatient)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Patient ID cannot be changed once set',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    _input('First Name', _firstName),
                    const SizedBox(height: 12),
                    _input('Last Name', _lastName),
                    const SizedBox(height: 12),
                    _input('Phone Number', _phone, type: TextInputType.phone),
                    const SizedBox(height: 12),
                    _input('Insurance Company', _insuranceCompany),
                    const SizedBox(height: 12),
                    _input('Insurance ID', _insuranceId),
                    const SizedBox(height: 12),
                    _input('Email', _email, type: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _input('Weight (kg)', _weight, type: TextInputType.number),
                    const SizedBox(height: 12),
                    _input('Weeks of pregnancy', _weeks, type: TextInputType.number),
                    const SizedBox(height: 20),
                    
                    // FHIR connection warning
                    if (!fhir.isConnected)
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
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_loading || (fhir.syncEnabled && !fhir.isConnected)) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rose, 
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
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
                            : const Text('Save Information'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
