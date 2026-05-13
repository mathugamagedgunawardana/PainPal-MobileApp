import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../data/storage.dart';
import '../services/app_services.dart';
import '../services/medication_reminder_service.dart';
import '../theme/shell_tokens.dart';
import '../widgets/custom_widgets.dart';
import 'patient_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = SettingsStorage();

  bool _loading = true;
  bool _medicationRemindersEnabled = true;
  bool _aiUseHealthData = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final med = await _storage.readMedicationRemindersEnabled();
    final aiData = await _storage.readAiUseHealthData();
    if (!mounted) {
      return;
    }
    setState(() {
      _medicationRemindersEnabled = med;
      _aiUseHealthData = aiData;
      _loading = false;
    });
  }

  Future<void> _onMedicationRemindersChanged(bool value) async {
    await _storage.saveMedicationRemindersEnabled(value);
    if (value) {
      await MedicationReminderService.instance.syncWithBackend(AppServices.auth);
    } else {
      await MedicationReminderService.instance.clearAllScheduled();
    }
    if (!mounted) {
      return;
    }
    setState(() => _medicationRemindersEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Medication reminders are on when your clinic sets a schedule.'
              : 'Medication reminders are off.',
        ),
      ),
    );
  }

  Future<void> _onAiHealthDataChanged(bool value) async {
    await _storage.saveAiUseHealthData(value);
    if (!mounted) {
      return;
    }
    setState(() => _aiUseHealthData = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'The AI assistant can use your logs and clinic summaries when you chat.'
              : 'The AI assistant will give general advice only until you turn this back on.',
        ),
      ),
    );
  }

  void _showFullDisclaimer(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Important disclaimer'),
        content: SingleChildScrollView(
          child: Text(
            'Educational purpose only\n\n'
            'This app is for educational and self-tracking purposes only. Predictions and '
            'classifications are not medical diagnoses.\n\n'
            'Consult healthcare professionals\n\n'
            'Always consult qualified healthcare professionals for diagnosis, treatment, and advice.\n\n'
            'No emergency use\n\n'
            'Do not use this app for emergencies. Call your local emergency number if you need urgent care.',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergencies'),
        content: Text(
          'If you or someone else may be having a stroke, severe head injury, sudden worst-ever '
          'headache, fever with stiff neck, or any life-threatening symptoms, call emergency '
          'services immediately. PainPal is not an emergency service.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _paddedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPatient =
        AppServices.auth.currentUser?.role == UserRole.patient;

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
          SectionHeader(
            title: 'Your account',
            subtitle: 'Profile and preferences on this device',
            illustrationIcon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _paddedCard(
            child: ListTile(
              leading: const Icon(Icons.badge_outlined, color: ShellTokens.limeMuted),
              title: const Text('Your profile'),
              subtitle: Text(
                'Name, condition summary, and account details',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PatientProfileScreen(),
                  ),
                );
              },
            ),
          ),
          if (isPatient) ...[
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Reminders',
              subtitle: 'How PainPal nudges you about care',
              illustrationIcon: Icons.notifications_outlined,
            ),
            const SizedBox(height: 12),
            _paddedCard(
              child: SwitchListTile.adaptive(
                secondary: const Icon(Icons.medication_liquid, color: ShellTokens.limeMuted),
                title: const Text('Medication reminders'),
                subtitle: Text(
                  'Daily notifications from the schedule your clinic saves for you (phone or tablet).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                value: _medicationRemindersEnabled,
                onChanged: _onMedicationRemindersChanged,
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Privacy',
              subtitle: 'Control what the in-app AI can see',
              illustrationIcon: Icons.shield_outlined,
            ),
            const SizedBox(height: 12),
            _paddedCard(
              child: SwitchListTile.adaptive(
                secondary: const Icon(Icons.psychology_outlined, color: ShellTokens.limeMuted),
                title: const Text('Let AI use my health data'),
                subtitle: Text(
                  'When on, the assistant can refer to your logs, MRI summaries on this device, '
                  'and clinic analytics. When off, it only gives general migraine guidance.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                value: _aiUseHealthData,
                onChanged: _onAiHealthDataChanged,
              ),
            ),
          ],
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Safety & support',
            subtitle: 'When not to rely on the app',
            illustrationIcon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 12),
          _paddedCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade400),
                  title: const Text('Medical disclaimer'),
                  subtitle: const Text('Educational use, not a diagnosis'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFullDisclaimer(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.emergency_outlined, color: Colors.red.shade300),
                  title: const Text('Emergencies'),
                  subtitle: const Text('When to call emergency services'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showEmergencyInfo(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'About',
            subtitle: 'App information',
            illustrationIcon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          _paddedCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PainPal', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Track migraines, review MRI insights, message your care team, and get '
                    'supportive guidance in one place.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
