import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/storage.dart';
import '../data/theme_provider.dart';
import '../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = SettingsStorage();
  final _baseUrlController = TextEditingController();
  final _patientIdController = TextEditingController();

  bool _loading = true;
  bool _notifRisk = true;
  bool _notifMedication = true;
  bool _notifDaily = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final baseUrl = await _storage.readBaseUrl();
    final patientId = await _storage.readPatientId();
    _baseUrlController.text = baseUrl ?? '';
    _patientIdController.text = patientId ?? '';
    _notifRisk = await _storage.getNotificationsRisk();
    _notifMedication = await _storage.getNotificationsMedication();
    _notifDaily = await _storage.getNotificationsDaily();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _storage.saveBaseUrl(_baseUrlController.text);
    await _storage.savePatientId(_patientIdController.text);
    await _storage.setNotificationsRisk(_notifRisk);
    await _storage.setNotificationsMedication(_notifMedication);
    await _storage.setNotificationsDaily(_notifDaily);
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // APPEARANCE SECTION
          SectionHeader(
            title: 'Appearance',
            subtitle: 'Customize how the app looks',
            illustrationIcon: Icons.palette,
          ),
          const SizedBox(height: 16),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return _SettingCard(
                title: 'Theme Mode',
                description: 'Choose between light and dark mode',
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ThemeOption(
                          icon: Icons.light_mode,
                          label: 'Light',
                          isSelected: !themeProvider.isDarkMode,
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.light);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeOption(
                          icon: Icons.dark_mode,
                          label: 'Dark',
                          isSelected: themeProvider.isDarkMode,
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

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
                hintText: 'http://localhost:3000 or your backend URL',
                prefixIcon: Icon(
                  Icons.link,
                  color: theme.colorScheme.primary,
                ),
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
                prefixIcon: Icon(
                  Icons.badge,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // NOTIFICATIONS SECTION
          SectionHeader(
            title: 'Notifications',
            subtitle: 'Choose which reminders and alerts you want',
            illustrationIcon: Icons.notifications,
          ),
          const SizedBox(height: 16),
          _SettingCard(
            title: 'Migraine risk alert',
            description: 'Notify when risk is high (>70%)',
            child: SwitchListTile(
              value: _notifRisk,
              onChanged: (v) => setState(() => _notifRisk = v),
              activeColor: const Color(0xFFB6F36B),
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            title: 'Medication reminder',
            description: 'Remind to take migraine medication',
            child: SwitchListTile(
              value: _notifMedication,
              onChanged: (v) => setState(() => _notifMedication = v),
              activeColor: const Color(0xFFB6F36B),
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            title: 'Daily tracking reminder',
            description: 'Remind to log symptoms each day',
            child: SwitchListTile(
              value: _notifDaily,
              onChanged: (v) => setState(() => _notifDaily = v),
              activeColor: const Color(0xFFB6F36B),
            ),
          ),
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
                      color: Colors.blue.shade700,
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
              border: Border.all(color: Colors.amber.shade700, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Educational Purpose Only',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app is for educational and self-tracking purposes only. The predictions and classifications provided by this app are NOT medical diagnoses.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Consult Healthcare Professionals',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Always consult qualified healthcare professionals for proper diagnosis, treatment recommendations, and medical advice.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Emergency Use',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This app should not be used for emergency medical situations. In case of emergency, please contact emergency services immediately.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
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
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
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
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A health-tracking application for migraine management and brain MRI analysis.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
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
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFB6F36B) : const Color(0xFF8BC34A))
              : (isDark ? const Color(0xFF171B22) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFB6F36B) : const Color(0xFF8BC34A))
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Colors.black
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.black
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


