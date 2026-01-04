import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/fhir_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isObscure = true;
  String _userType = 'patient';

  static const patientPink = Color(0xFFF3A7BD);
  static const doctorBlue = Color(0xFF80B8F0);

  Color get _primaryColor => _userType == 'patient' ? patientPink : doctorBlue;

  String _generateEmail(String username) {
    return '$username@pregnancy-tracker.com';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fhirProvider = Provider.of<FhirProvider>(context, listen: false);
      fhirProvider.testConnection();
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final username = _usernameController.text.trim();
      final email = _generateEmail(username);
      
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      await _redirectToHomePage(userCredential.user!.uid);

    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'User not found';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else {
        message = 'Login failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _redirectToHomePage(String uid) async {
    try {
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();

      if (doctorDoc.exists) {
        final doctorData = doctorDoc.data();
        final hasBasicInfo = doctorData?['firstName'] != null && 
                            doctorData?['firstName'].toString().isNotEmpty == true;
        
        if (hasBasicInfo) {
          Navigator.pushReplacementNamed(context, '/doctorMain');
        } else {
          Navigator.pushReplacementNamed(context, '/doctorInfo');
        }
        return;
      }

      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(uid)
          .get();

      if (patientDoc.exists) {
        final patientData = patientDoc.data();
        final hasBasicInfo = patientData?['patientId'] != null && 
                            patientData?['patientId'].toString().isNotEmpty == true;
        
        if (hasBasicInfo) {
          Navigator.pushReplacementNamed(context, '/patientMain');
        } else {
          Navigator.pushReplacementNamed(context, '/patientInfo');
        }
        return;
      }

      _showUserTypeDialog(uid);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User type check failed: $e')),
      );
    }
  }

  void _showUserTypeDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select User Type'),
        content: const Text('Please select your user type to continue'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createUserProfile(uid, 'patient');
            },
            child: const Text('Patient'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createUserProfile(uid, 'doctor');
            },
            child: const Text('Doctor'),
          ),
        ],
      ),
    );
  }

  Future<void> _createUserProfile(String uid, String type) async {
    try {
      final username = _usernameController.text.trim();
      
      if (type == 'patient') {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(uid)
            .set({
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacementNamed(context, '/patientInfo');
      } else {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .set({
          'username': username,
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pushReplacementNamed(context, '/doctorInfo');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user profile: $e')),
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final username = _usernameController.text.trim();
      final email = _generateEmail(username);
      
      final UserCredential userCredential = 
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      await _createUserProfile(userCredential.user!.uid, _userType);

    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Username already exists';
      } else {
        message = 'Registration failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: _primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pregnancy Tracker',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track Your Pregnancy Health',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Consumer<FhirProvider>(
                  builder: (context, fhir, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: fhir.isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fhir.isConnected ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            fhir.isConnected ? Icons.check_circle : Icons.warning,
                            color: fhir.isConnected ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fhir.isConnected ? 'FHIR Server Connected' : 'FHIR Server Not Connected',
                              style: TextStyle(
                                color: fhir.isConnected ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!fhir.isConnected)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () => fhir.testConnection(),
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Select User Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Patient'),
                              selected: _userType == 'patient',
                              onSelected: (selected) {
                                setState(() {
                                  _userType = 'patient';
                                });
                              },
                              selectedColor: patientPink,
                              labelStyle: TextStyle(
                                color: _userType == 'patient' 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Doctor'),
                              selected: _userType == 'doctor',
                              onSelected: (selected) {
                                setState(() {
                                  _userType = 'doctor';
                                });
                              },
                              selectedColor: doctorBlue,
                              labelStyle: TextStyle(
                                color: _userType == 'doctor' 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers and underscore';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
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
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _register,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: _primaryColor),
                    ),
                    child: Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextButton(
                  onPressed: _loading ? null : _showResetPasswordDialog,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Please contact administrator to reset your password as the system uses auto-generated email addresses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}