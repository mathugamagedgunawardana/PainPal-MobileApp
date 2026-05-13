import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../services/app_services.dart';
import '../services/attack_timer_service.dart';
import '../services/medication_reminder_service.dart';
import '../services/quick_access_actions.dart';
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
  bool _quickAccessExpanded = false;

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

  void _onAttackTimerFab(BuildContext context) {
    final t = AppServices.attackTimer;
    if (!t.isRunning) {
      t.start();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ShellTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return ListenableBuilder(
          listenable: t,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Attack timer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AttackTimerService.formatElapsed(t.elapsed),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stop when you are ready to describe the attack in the log.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        final r = t.consumeStopForLog();
                        Navigator.of(sheetCtx).pop();
                        if (r == null || !mounted) {
                          return;
                        }
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => MigraineFormScreen(
                              initialDurationHours: r.durationHours,
                              attackStartedAt: r.startedAt,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Stop & log attack'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ShellTokens.lime,
                        foregroundColor: ShellTokens.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        t.cancel();
                        Navigator.of(sheetCtx).pop();
                      },
                      child: const Text('Discard timer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPatientProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PatientProfileScreen(),
      ),
    );
  }

  void _collapseQuickAccess() {
    if (_quickAccessExpanded) {
      setState(() => _quickAccessExpanded = false);
    }
  }

  Widget _quickAccessMiniFab({
    required Object heroTag,
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton.small(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 8,
        tooltip: tooltip,
        child: Icon(icon, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Space for dock (72) + padding (8) + elevated center control (~28) + margin
    final fabBottom = bottomInset + 108;
    final isPatient =
        AppServices.auth.currentUser?.role == UserRole.patient;

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
              builder: (_) => const SettingsScreen(),
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
            child: ListenableBuilder(
              listenable: AppServices.attackTimer,
              builder: (context, _) {
                final running = AppServices.attackTimer.isRunning;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_quickAccessExpanded) ...[
                      _quickAccessMiniFab(
                        heroTag: 'qa_emergency',
                        icon: Icons.contact_phone_outlined,
                        tooltip: 'Emergency contacts',
                        backgroundColor: Colors.red.shade800,
                        onPressed: () async {
                          _collapseQuickAccess();
                          await QuickAccessActions.openEmergencyContacts(context);
                        },
                      ),
                      _quickAccessMiniFab(
                        heroTag: 'qa_doctor',
                        icon: Icons.local_hospital_outlined,
                        tooltip: 'Call doctor',
                        backgroundColor: Colors.blue.shade800,
                        onPressed: () async {
                          _collapseQuickAccess();
                          await QuickAccessActions.openCallDoctor(context);
                        },
                      ),
                      _quickAccessMiniFab(
                        heroTag: 'qa_share_loc',
                        icon: Icons.share_location,
                        tooltip: 'Share location',
                        backgroundColor: Colors.teal.shade700,
                        onPressed: () async {
                          _collapseQuickAccess();
                          await QuickAccessActions.shareLocation(context);
                        },
                      ),
                      _quickAccessMiniFab(
                        heroTag: 'qa_severe',
                        icon: Icons.warning_amber_rounded,
                        tooltip: 'Severe symptom checklist',
                        backgroundColor: Colors.deepOrange.shade800,
                        onPressed: () {
                          _collapseQuickAccess();
                          QuickAccessActions.openSevereChecklist(context);
                        },
                      ),
                    ],
                    FloatingActionButton(
                      heroTag: 'fab_quick_access',
                      onPressed: () {
                        setState(() {
                          _quickAccessExpanded = !_quickAccessExpanded;
                        });
                      },
                      backgroundColor: _quickAccessExpanded
                          ? Colors.grey.shade800
                          : const Color(0xFFE64A45),
                      foregroundColor: Colors.white,
                      elevation: 10,
                      tooltip: _quickAccessExpanded
                          ? 'Close quick access'
                          : 'Quick access',
                      child: Icon(
                        _quickAccessExpanded ? Icons.close : Icons.bolt,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isPatient) ...[
                      FloatingActionButton(
                        heroTag: 'fab_attack_timer',
                        onPressed: () => _onAttackTimerFab(context),
                        backgroundColor: running
                            ? Colors.amber.shade700
                            : ShellTokens.lime,
                        foregroundColor: ShellTokens.bg,
                        elevation: 10,
                        tooltip: running
                            ? 'Attack timer — tap to stop or log'
                            : 'Start migraine attack timer',
                        child: Icon(
                          running ? Icons.timer : Icons.timer_outlined,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FloatingActionButton(
                      heroTag: 'fab_chat',
                      onPressed: _openChat,
                      backgroundColor: ShellTokens.lime,
                      foregroundColor: ShellTokens.bg,
                      elevation: 10,
                      tooltip: 'Clinic chat & AI assistant',
                      child: const Icon(Icons.chat_bubble_rounded, size: 26),
                    ),
                  ],
                );
              },
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
