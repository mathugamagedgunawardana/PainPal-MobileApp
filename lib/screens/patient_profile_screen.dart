import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_services.dart';
import '../theme/shell_tokens.dart';

/// Full-screen profile (LinkedIn-style summary) for the signed-in user.
class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  static String _initials(String? name, String? emailFallback) {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) {
      final parts = n.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n[0].toUpperCase();
    }
    final e = emailFallback ?? '?';
    return e.isNotEmpty ? e[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AppServices.auth;
    final user = auth.currentUser;
    final patient = auth.patientProfile;
    final doctor = auth.doctorProfile;

    final displayName = patient != null && patient.name.trim().isNotEmpty
        ? patient.name
        : doctor?.name ??
            user?.email ??
            'Account';

    final headline = patient != null &&
            patient.condition != null &&
            patient.condition!.trim().isNotEmpty
        ? patient.condition!.trim()
        : doctor != null
            ? '${doctor.specialization} · ${doctor.clinicId}'
            : user?.email ?? '';

    final initials = _initials(
      patient?.name ?? doctor?.name,
      user?.email,
    );

    return Scaffold(
      backgroundColor: ShellTokens.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: ShellTokens.surface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ShellTokens.surface,
                  ShellTokens.surface.withValues(alpha: 0.85),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: ShellTokens.lime.withValues(alpha: 0.22),
                  foregroundColor: ShellTokens.lime,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (headline.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    headline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade400,
                      height: 1.35,
                    ),
                  ),
                ],
                if (user != null) ...[
                  const SizedBox(height: 10),
                  Chip(
                    label: Text(
                      user.role.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: ShellTokens.lime.withValues(alpha: 0.15),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (patient != null) ...[
                  _ProfileTile(
                    icon: Icons.cake_outlined,
                    label: 'Date of birth',
                    value: DateFormat.yMMMMd().format(patient.dateOfBirth.toLocal()),
                  ),
                  if (patient.gender != null && patient.gender!.trim().isNotEmpty)
                    _ProfileTile(
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: patient.gender!,
                    ),
                  if (patient.phone != null && patient.phone!.trim().isNotEmpty)
                    _ProfileTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: patient.phone!,
                    ),
                  if (patient.email != null && patient.email!.trim().isNotEmpty)
                    _ProfileTile(
                      icon: Icons.alternate_email,
                      label: 'Profile email',
                      value: patient.email!,
                    ),
                  if (patient.address != null && patient.address!.trim().isNotEmpty)
                    _ProfileTile(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: patient.address!,
                    ),
                  if (patient.ehrRecordId != null &&
                      patient.ehrRecordId!.trim().isNotEmpty)
                    _ProfileTile(
                      icon: Icons.badge_outlined,
                      label: 'EHR record',
                      value: patient.ehrRecordId!,
                    ),
                ] else if (doctor != null) ...[
                  _ProfileTile(
                    icon: Icons.medical_services_outlined,
                    label: 'Specialization',
                    value: doctor.specialization,
                  ),
                  _ProfileTile(
                    icon: Icons.local_hospital_outlined,
                    label: 'Clinic ID',
                    value: doctor.clinicId,
                  ),
                ],
                if (user != null)
                  _ProfileTile(
                    icon: Icons.login,
                    label: 'Account email',
                    value: user.email,
                  ),
                if (patient == null &&
                    doctor == null &&
                    user != null &&
                    user.email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Extended profile appears when you sign in with a role that includes a clinic profile.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: ShellTokens.lime.withValues(alpha: 0.85)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
