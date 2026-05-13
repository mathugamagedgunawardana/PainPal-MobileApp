import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/shell_tokens.dart';

/// LinkedIn-style top row: avatar + name opens the drawer.
class AppShellHeader extends StatelessWidget {
  const AppShellHeader({
    super.key,
    required this.onOpenDrawer,
  });

  final VoidCallback onOpenDrawer;

  String _initials() {
    final name = AppServices.auth.patientProfile?.name.trim();
    if (name != null && name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
      }
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
    final email = AppServices.auth.currentUser?.email ?? '?';
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String _displayName() {
    final n = AppServices.auth.patientProfile?.name.trim();
    if (n != null && n.isNotEmpty) {
      return n;
    }
    return AppServices.auth.currentUser?.email ?? 'Guest';
  }

  String _subtitle() {
    final email = AppServices.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      return 'Painpal';
    }
    final at = email.indexOf('@');
    if (at > 0) {
      return '@${email.substring(0, at)}';
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShellTokens.surface,
      child: InkWell(
        onTap: onOpenDrawer,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            8 + MediaQuery.paddingOf(context).top,
            16,
            12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ShellTokens.lime.withValues(alpha: 0.25),
                foregroundColor: ShellTokens.lime,
                child: Text(
                  _initials(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayName(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
