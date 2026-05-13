import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/painpal_app_colors.dart';

/// Top row: gradient avatar + name opens the drawer; theme toggle (🌙 / ☀️).
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
    final pp = context.pp;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: pp.bgCard,
      child: InkWell(
        onTap: onOpenDrawer,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            8 + MediaQuery.paddingOf(context).top,
            12,
            12,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
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
                            color: pp.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: pp.textTertiary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                onPressed: () => AppServices.theme.toggleLightDark(),
                icon: Text(
                  isDark ? '☀️' : '🌙',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: pp.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
