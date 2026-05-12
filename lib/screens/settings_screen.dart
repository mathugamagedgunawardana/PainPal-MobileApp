import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../data/storage.dart';
import '../services/app_services.dart';
import '../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onSignedOut});

  final VoidCallback? onSignedOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = SettingsStorage();
  final _baseUrlController = TextEditingController();
  final _patientIdController = TextEditingController();
  final _chatDoctorProfileIdController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baseUrl = await _storage.readBaseUrl();
    final patientId = await _storage.readPatientId();
    final chatDoctorId = await _storage.readChatDoctorProfileId();
    _baseUrlController.text = baseUrl ?? '';
    _patientIdController.text = patientId ?? '';
    _chatDoctorProfileIdController.text = chatDoctorId ?? '';
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'You will need to sign in again to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await AppServices.auth.logout();
    widget.onSignedOut?.call();
  }

  Future<void> _save() async {
    await _storage.saveBaseUrl(_baseUrlController.text);
    await _storage.savePatientId(_patientIdController.text);
    await _storage.saveChatDoctorProfileId(_chatDoctorProfileIdController.text);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Settings saved successfully'),
          ],
        ),
        backgroundColor: Color(0xFFB6F36B),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _patientIdController.dispose();
    _chatDoctorProfileIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: const Color(0xFF171B22),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.onSignedOut != null) ...[
            SectionHeader(
              title: 'Account',
              subtitle: 'Sign out of Painpal on this device',
              illustrationIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (AppServices.auth.currentUser != null &&
                      AppServices.auth.currentUser!.email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Signed in as ${AppServices.auth.currentUser!.email}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent.shade100,
                      side: BorderSide(
                        color: Colors.redAccent.shade200.withValues(alpha: 0.6),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
          // API SETTINGS SECTION
          SectionHeader(
            title: 'API Configuration',
            subtitle: 'Connect to your backend server',
            illustrationIcon: Icons.api,
          ),
          const SizedBox(height: 16),
          _SettingCard(
            title: 'API Base URL',
            description: 'The address of your backend server',
            child: TextField(
              controller: _baseUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://your-backend-host',
                filled: true,
                fillColor: const Color(0xFF171B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                prefixIcon: const Icon(Icons.link, color: Color(0xFFB6F36B)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SettingCard(
            title: 'Patient ID',
            description: 'Unique identifier for your patient records (optional)',
            child: TextField(
              controller: _patientIdController,
              decoration: InputDecoration(
                hintText: 'e.g., patient-12345',
                filled: true,
                fillColor: const Color(0xFF171B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                prefixIcon:
                    const Icon(Icons.badge, color: Color(0xFFB6F36B)),
              ),
            ),
          ),
          if (AppServices.auth.currentUser?.role == UserRole.patient) ...[
            const SizedBox(height: 16),
            _SettingCard(
              title: 'Doctor profile ID (clinic chat)',
              description:
                  'Your doctor’s profile id from the web app (Mongo ObjectId). Used to open messaging when you have no existing conversation.',
              child: TextField(
                controller: _chatDoctorProfileIdController,
                decoration: InputDecoration(
                  hintText: 'Paste doctor profile id',
                  filled: true,
                  fillColor: const Color(0xFF171B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade700),
                  ),
                  prefixIcon:
                      const Icon(Icons.medical_services_outlined, color: Color(0xFFB6F36B)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // TEST CONNECTION BUTTON
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade600, width: 1),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure you have internet connection and the API server is running.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SAVE BUTTON
          MigraineButton(
            onPressed: _save,
            label: 'Save Settings',
            icon: Icons.save,
          ),
          const SizedBox(height: 32),

          // DISCLAIMER SECTION
          SectionHeader(
            title: '⚠️ Important Disclaimer',
            subtitle: 'Please read carefully',
            illustrationIcon: Icons.warning_amber,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade600, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Purpose Only',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app is for educational and self-tracking purposes only. The predictions and classifications provided by this app are NOT medical diagnoses.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Consult Healthcare Professionals',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Always consult qualified healthcare professionals for proper diagnosis, treatment recommendations, and medical advice.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Emergency Use',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app should not be used for emergency medical situations. In case of emergency, please contact emergency services immediately.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ABOUT SECTION
          SectionHeader(
            title: 'About',
            subtitle: 'Application information',
            illustrationIcon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade700),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PainPal',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A health-tracking application for migraine management and brain MRI analysis.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _SettingCard({
    Key? key,
    required this.title,
    required this.description,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

