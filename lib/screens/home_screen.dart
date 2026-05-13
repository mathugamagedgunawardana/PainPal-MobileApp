import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../services/medication_reminder_service.dart';
import '../theme/shell_tokens.dart';
import '../widgets/app_paynx_bottom_nav.dart';
import '../widgets/app_shell_header.dart';
import '../widgets/chat_widget.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'migraine_form_screen.dart';
import 'mri_upload_screen.dart';
import 'log_attack_screen.dart';
import 'patient_profile_screen.dart';
import 'schedule_appointment_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSignedOut});

  /// Called after local credentials are cleared (e.g. from Settings).
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  late final List<Widget> _tabs = [
    const LogAttackScreen(embedInShell: true),
    const AnalyticsScreen(embedInShell: true),
    const MigraineFormScreen(embedInShell: true),
    const HistoryScreen(embedInShell: true),
    const MriUploadScreen(embedInShell: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MedicationReminderService.instance.syncWithBackend(AppServices.auth);
    });
  }

  Future<void> _confirmSignOut(BuildContext context) async {
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
    widget.onSignedOut();
  }

  void _openChat() {
    showDialog<void>(
      context: context,
      builder: (ctx) => const ChatDialog(),
    );
  }

  void _openPatientProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PatientProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Space for dock (72) + padding (8) + elevated center control (~28) + margin
    final fabBottom = bottomInset + 108;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ShellTokens.bg,
      drawer: _AppDrawer(
        onCloseDrawer: () => Navigator.of(context).pop(),
        onSignedOut: () => _confirmSignOut(context),
        onOpenSettings: () {
          Navigator.of(context).pop();
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(onSignedOut: widget.onSignedOut),
            ),
          );
        },
        onOpenPatientProfile: () {
          Navigator.of(context).pop();
          _openPatientProfile();
        },
        onOpenScheduleAppointment: () {
          Navigator.of(context).pop();
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const ScheduleAppointmentScreen(),
            ),
          );
        },
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppShellHeader(
                onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: _tabs,
                ),
              ),
              AppPaynxBottomNav(
                currentIndex: _index,
                onSelect: (i) => setState(() => _index = i),
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: fabBottom,
            child: FloatingActionButton(
              onPressed: _openChat,
              backgroundColor: ShellTokens.lime,
              foregroundColor: ShellTokens.bg,
              elevation: 10,
              tooltip: 'Clinic chat & AI assistant',
              child: const Icon(Icons.chat_bubble_rounded, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.onCloseDrawer,
    required this.onSignedOut,
    required this.onOpenSettings,
    required this.onOpenPatientProfile,
    required this.onOpenScheduleAppointment,
  });

  final VoidCallback onCloseDrawer;
  final Future<void> Function() onSignedOut;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPatientProfile;
  final VoidCallback onOpenScheduleAppointment;

  String _initials() {
    final name = AppServices.auth.patientProfile?.name.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
    final dn = AppServices.auth.doctorProfile?.name.trim();
    if (dn != null && dn.isNotEmpty) {
      return dn.length >= 2 ? dn.substring(0, 2).toUpperCase() : dn[0].toUpperCase();
    }
    final email = AppServices.auth.currentUser?.email ?? '?';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String _displayName() {
    final n = AppServices.auth.patientProfile?.name.trim();
    if (n != null && n.isNotEmpty) {
      return n;
    }
    final d = AppServices.auth.doctorProfile?.name.trim();
    if (d != null && d.isNotEmpty) {
      return d;
    }
    return AppServices.auth.currentUser?.email ?? 'Account';
  }

  String _headline() {
    final c = AppServices.auth.patientProfile?.condition?.trim();
    if (c != null && c.isNotEmpty) {
      return c;
    }
    final doc = AppServices.auth.doctorProfile;
    if (doc != null) {
      return doc.specialization;
    }
    final email = AppServices.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      return 'Painpal member';
    }
    final at = email.indexOf('@');
    if (at > 0) {
      return '@${email.substring(0, at)}';
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: ShellTokens.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenPatientProfile,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: ShellTokens.lime.withValues(alpha: 0.2),
                        foregroundColor: ShellTokens.lime,
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _headline(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'View profile',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: ShellTokens.lime,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade600,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: ShellTokens.lime),
              title: const Text('Settings'),
              onTap: onOpenSettings,
            ),
            ListTile(
              leading: const Icon(Icons.event_available, color: ShellTokens.lime),
              title: const Text('Schedule appointment'),
              subtitle: Text(
                'With your linked doctors',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: onOpenScheduleAppointment,
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent.shade100),
              title: Text(
                'Sign out',
                style: TextStyle(color: Colors.redAccent.shade100),
              ),
              onTap: () async {
                onCloseDrawer();
                await onSignedOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
