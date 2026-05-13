import 'package:flutter/material.dart';

import '../data/auth_models.dart';
import '../services/app_services.dart';
import '../services/attack_timer_service.dart';
import '../services/medication_reminder_service.dart';
import '../services/quick_access_actions.dart';
import '../theme/painpal_app_colors.dart';
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

  void _onAttackTimerFab(BuildContext context) {
    final t = AppServices.attackTimer;
    if (!t.isRunning) {
      t.start();
      return;
    }
    final pp = context.pp;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pp.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PainpalRadii.xl)),
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
                          color: sheetCtx.pp.borderDefault,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      '⏱️ Attack timer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: sheetCtx.pp.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AttackTimerService.formatElapsed(t.elapsed),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: sheetCtx.pp.accentPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stop when you are ready to describe the attack in the log.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: sheetCtx.pp.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isPatient =
        AppServices.auth.currentUser?.role == UserRole.patient;
    final pp = context.pp;
    final chatBottom = bottomInset + 8 + 72 + (isPatient ? 48 : 0) + 12;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: pp.bgTertiary,
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
        onOpenEmergencyContacts: () {
          Navigator.of(context).pop();
          QuickAccessActions.openEmergencyContacts(context);
        },
        onOpenCallDoctor: () {
          Navigator.of(context).pop();
          QuickAccessActions.openCallDoctor(context);
        },
        onShareLocation: () {
          Navigator.of(context).pop();
          QuickAccessActions.shareLocation(context);
        },
        onOpenSevereChecklist: () {
          Navigator.of(context).pop();
          QuickAccessActions.openSevereChecklist(context);
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
              if (isPatient)
                _ShellTimerBar(onPressed: () => _onAttackTimerFab(context)),
              AppPaynxBottomNav(
                currentIndex: _index,
                onSelect: (i) => setState(() => _index = i),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: chatBottom,
            child: Material(
              color: pp.accentSecondary,
              elevation: 6,
              shadowColor: pp.shadowElevated.first.color,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openChat,
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Text('💬', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellTimerBar extends StatelessWidget {
  const _ShellTimerBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    return ListenableBuilder(
      listenable: AppServices.attackTimer,
      builder: (context, _) {
        final running = AppServices.attackTimer.isRunning;
        return Material(
          color: pp.bgSecondary,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: pp.borderDefault),
                  bottom: BorderSide(color: pp.borderDefault),
                ),
              ),
              child: Row(
                children: [
                  const Text('⏱️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      running
                          ? AttackTimerService.formatElapsed(
                              AppServices.attackTimer.elapsed,
                            )
                          : 'Pain timer — tap to start or open',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: pp.textPrimary,
                          ),
                    ),
                  ),
                  if (running)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pp.accentWarningLight,
                        borderRadius:
                            BorderRadius.circular(PainpalRadii.pill),
                      ),
                      child: Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pp.accentWarning,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
    required this.onOpenEmergencyContacts,
    required this.onOpenCallDoctor,
    required this.onShareLocation,
    required this.onOpenSevereChecklist,
  });

  final VoidCallback onCloseDrawer;
  final Future<void> Function() onSignedOut;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenPatientProfile;
  final VoidCallback onOpenScheduleAppointment;
  final VoidCallback onOpenEmergencyContacts;
  final VoidCallback onOpenCallDoctor;
  final VoidCallback onShareLocation;
  final VoidCallback onOpenSevereChecklist;

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
    final pp = context.pp;

    return Drawer(
      backgroundColor: pp.bgCard,
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [pp.accentPrimary, pp.accentSecondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                                color: pp.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _headline(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: pp.textSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '👤 View profile',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: pp.accentPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: pp.textTertiary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: pp.borderDefault),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: pp.accentPrimary),
              title: Text('Settings', style: TextStyle(color: pp.textPrimary)),
              onTap: onOpenSettings,
            ),
            ListTile(
              leading: Icon(Icons.event_available, color: pp.accentPrimary),
              title: Text(
                '📋 Schedule appointment',
                style: TextStyle(color: pp.textPrimary),
              ),
              subtitle: Text(
                'With your linked doctors',
                style: TextStyle(color: pp.textSecondary, fontSize: 12),
              ),
              onTap: onOpenScheduleAppointment,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Quick help ⚡',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: pp.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: Text('📞', style: TextStyle(fontSize: 22)),
              title: Text('Emergency contacts', style: TextStyle(color: pp.textPrimary)),
              onTap: onOpenEmergencyContacts,
            ),
            ListTile(
              leading: Text('👩‍⚕️', style: TextStyle(fontSize: 22)),
              title: Text('Call doctor / clinic', style: TextStyle(color: pp.textPrimary)),
              onTap: onOpenCallDoctor,
            ),
            ListTile(
              leading: Text('📍', style: TextStyle(fontSize: 22)),
              title: Text('Share location', style: TextStyle(color: pp.textPrimary)),
              onTap: onShareLocation,
            ),
            ListTile(
              leading: Text('⚠️', style: TextStyle(fontSize: 22)),
              title: Text('Severe symptoms', style: TextStyle(color: pp.textPrimary)),
              onTap: onOpenSevereChecklist,
            ),
            const Divider(height: 32),
            ListTile(
              leading: Icon(Icons.logout, color: pp.accentDanger),
              title: Text(
                'Sign out',
                style: TextStyle(color: pp.accentDanger),
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
