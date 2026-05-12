/// Example implementation of MongoDB integration in screens
/// This file shows how to use AuthService and PatientDataService
/// in your Flutter screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:painpal/data/auth_service.dart';
// import 'package:painpal/data/patient_data_service.dart';
// import 'package:painpal/data/auth_models.dart';
// import 'package:painpal/data/models.dart';

/*

// ============================================================================
// EXAMPLE 1: Login Screen
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final response = await authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        // Navigate to home based on user role
        if (response.user.role == UserRole.patient) {
          Navigator.of(context).pushReplacementNamed('/patient-home');
        } else if (response.user.role == UserRole.doctor) {
          Navigator.of(context).pushReplacementNamed('/doctor-home');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Login failed: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to PainPal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Register Screen
// ============================================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final response = await authService.register(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
        name: _nameController.text,
        dateOfBirth: _selectedRole == UserRole.patient
            ? DateTime(2000, 1, 1)
            : null,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = 'Registration failed: ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = 'Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Join PainPal',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter a strong password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: [
                DropdownMenuItem(
                  value: UserRole.patient,
                  child: const Text('Patient'),
                ),
                DropdownMenuItem(
                  value: UserRole.doctor,
                  child: const Text('Doctor'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Submit Migraine Event
// ============================================================================

class SubmitMigraineScreen extends StatefulWidget {
  const SubmitMigraineScreen({Key? key}) : super(key: key);

  @override
  State<SubmitMigraineScreen> createState() => _SubmitMigraineScreenState();
}

class _SubmitMigraineScreenState extends State<SubmitMigraineScreen> {
  int _duration = 4;
  int _frequency = 2;
  int _intensity = 5;
  String _location = 'Unilateral';
  String _character = 'Throbbing';
  bool _nausea = false;
  bool _phonophobia = false;
  bool _photophobia = false;
  bool _isSubmitting = false;

  Future<void> _submitMigraine() async {
    setState(() => _isSubmitting = true);

    try {
      final patientService = context.read<PatientDataService>();

      final attack = MigraineAttack(
        durationHours: _duration,
        frequencyPerMonth: _frequency,
        location: _location,
        character: _character,
        intensity: _intensity,
        nausea: _nausea ? 1 : 0,
        vomit: 0,
        phonophobia: _phonophobia ? 1 : 0,
        photophobia: _photophobia ? 1 : 0,
        visual: 0,
        sensory: 0,
        dysphasia: 0,
        dysarthria: 0,
        vertigo: 0,
        tinnitus: 0,
        hypoacusis: 0,
        diplopia: 0,
        defect: 0,
        ataxia: 0,
        conscience: 0,
        paresthesia: 0,
      );

      final response = await patientService.submitMigraineEvent(attack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migraine recorded!\nType: ${response.predictedType}'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Migraine Attack')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intensity: $_intensity/10'),
                    Slider(
                      value: _intensity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_intensity',
                      onChanged: (value) {
                        setState(() => _intensity = value.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Duration: $_duration hours'),
                    Slider(
                      value: _duration.toDouble(),
                      min: 1,
                      max: 72,
                      divisions: 71,
                      label: '${_duration}h',
                      onChanged: (value) {
                        setState(() => _duration = value.toInt());
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _location,
                      decoration: const InputDecoration(labelText: 'Location'),
                      items: ['Unilateral', 'Bilateral']
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _location = value ?? _location);
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Nausea'),
                      value: _nausea,
                      onChanged: (value) {
                        setState(() => _nausea = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Sound Sensitivity (Phonophobia)'),
                      value: _phonophobia,
                      onChanged: (value) {
                        setState(() => _phonophobia = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Light Sensitivity (Photophobia)'),
                      value: _photophobia,
                      onChanged: (value) {
                        setState(() => _photophobia = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitMigraine,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Migraine Record'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Upload MRI Scan
// ============================================================================

class UploadMriScreen extends StatefulWidget {
  const UploadMriScreen({Key? key}) : super(key: key);

  @override
  State<UploadMriScreen> createState() => _UploadMriScreenState();
}

class _UploadMriScreenState extends State<UploadMriScreen> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _result;

  Future<void> _uploadMri() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final patientService = context.read<PatientDataService>();
      final response = await patientService.submitMriScan(
        image: _selectedImage!,
      );

      setState(() {
        _result = 'Prediction: ${response.prediction}\n'
            'Confidence: ${(response.confidence * 100).toStringAsFixed(1)}%';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'MRI uploaded!\n${response.prediction}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload MRI Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Text('No image selected'),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Use image_picker to select image
                // final picker = ImagePicker();
                // final pickedFile = await picker.pickImage(
                //   source: ImageSource.gallery,
                // );
                // if (pickedFile != null) {
                //   setState(() => _selectedImage = File(pickedFile.path));
                // }
              },
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadMri,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload MRI Scan'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_result!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: View History
// ============================================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MigraineEvent>> _migraineHistory;
  late Future<List<MriScanData>> _mriHistory;

  @override
  void initState() {
    super.initState();
    final patientService = context.read<PatientDataService>();
    _migraineHistory = patientService.getMigraineHistory(limit: 20);
    _mriHistory = patientService.getMriHistory(limit: 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: TabBarView(
        children: [
          // Migraine History Tab
          FutureBuilder<List<MigraineEvent>>(
            future: _migraineHistory,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Center(child: Text('No migraine events recorded'));
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text('Severity: ${event.severity}/10'),
                    subtitle: Text(event.startDatetime.toString()),
                    trailing: Text(event.duration ?? 'N/A'),
                  );
                },
              );
            },
          ),
          // MRI History Tab
          FutureBuilder<List<MriScanData>>(
            future: _mriHistory,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final scans = snapshot.data ?? [];

              if (scans.isEmpty) {
                return const Center(child: Text('No MRI scans found'));
              }

              return ListView.builder(
                itemCount: scans.length,
                itemBuilder: (context, index) {
                  final scan = scans[index];
                  return ListTile(
                    title: Text(scan.prediction),
                    subtitle:
                        Text('Confidence: ${(scan.confidence * 100).toStringAsFixed(1)}%'),
                    trailing: Text(scan.createdAt?.toString() ?? 'N/A'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

*/

