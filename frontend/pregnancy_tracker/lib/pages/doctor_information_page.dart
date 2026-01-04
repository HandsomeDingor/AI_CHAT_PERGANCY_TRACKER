import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorInformationPage extends StatefulWidget {
  const DoctorInformationPage({super.key});

  @override
  State<DoctorInformationPage> createState() => _DoctorInformationPageState();
}

class _DoctorInformationPageState extends State<DoctorInformationPage> {
  final _firstName = TextEditingController();
  final _lastName  = TextEditingController();
  final _phone     = TextEditingController();
  final _hospital  = TextEditingController();
  final _licenseNo = TextEditingController();
  final _email     = TextEditingController();
  final _years     = TextEditingController();
  final _working   = TextEditingController();

  bool _loading = false;

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
          .collection('doctors').doc(uid).get();
      final d = doc.data();
      if (d != null) {
        _firstName.text = d['firstName'] ?? '';
        _lastName.text  = d['lastName'] ?? '';
        _phone.text     = d['phone'] ?? '';
        _hospital.text  = d['hospital'] ?? '';
        _licenseNo.text = d['licenseNo'] ?? '';
        _email.text     = d['email'] ?? '';
        _years.text     = (d['yearsOfExperience']?.toString() ?? '');
        _working.text   = d['workingHours'] ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw 'No UID';

      final data = {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'hospital': _hospital.text.trim(),
        'licenseNo': _licenseNo.text.trim(),
        'email': _email.text.trim(),
        'yearsOfExperience': int.tryParse(_years.text.trim()) ?? 0,
        'workingHours': _working.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('doctors').doc(uid)
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firestore')),
      );
      Navigator.pushReplacementNamed(context, '/doctorMain');
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
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _hospital.dispose();
    _licenseNo.dispose();
    _email.dispose();
    _years.dispose();
    _working.dispose();
    super.dispose();
  }

  Widget _input(String label, TextEditingController c, {TextInputType? type}) {
    return TextField(
      controller: c, keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        filled: true, fillColor: const Color(0xFFF7FAFF),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF80B8F0);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Basic Information')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Please enter your information.',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              _input('First Name', _firstName),
              const SizedBox(height: 12),
              _input('Last Name', _lastName),
              const SizedBox(height: 12),
              _input('Phone Number', _phone, type: TextInputType.phone),
              const SizedBox(height: 12),
              _input('Hospital / Clinic', _hospital),
              const SizedBox(height: 12),
              _input('License NO.', _licenseNo),
              const SizedBox(height: 12),
              _input('Email', _email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _input('Years of Experience', _years, type: TextInputType.number),
              const SizedBox(height: 12),
              _input('Working Hours', _working),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('save'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('cancel'),
                ),
              ),
            ],
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
  }
}
