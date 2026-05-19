import 'package:flutter/material.dart';

import '../theme/shell_tokens.dart';

/// Five-slot dock with an elevated center action (Paynx-style).
class AppPaynxBottomNav extends StatelessWidget {
  const AppPaynxBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const double _dockHeight = 72;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      child: Container(
        height: _dockHeight,
        decoration: BoxDecoration(
          color: ShellTokens.dock,
          borderRadius: BorderRadius.circular(ShellTokens.dockRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SideSlot(
              selected: currentIndex == 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => onSelect(0),
            ),
            _SideSlot(
              selected: currentIndex == 1,
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              onTap: () => onSelect(1),
            ),
            _CenterFab(
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
            ),
            _SideSlot(
              selected: currentIndex == 3,
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () => onSelect(3),
            ),
            _SideSlot(
              selected: currentIndex == 4,
              icon: Icons.document_scanner_outlined,
              label: 'MRI',
              onTap: () => onSelect(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideSlot extends StatelessWidget {
  const _SideSlot({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ShellTokens.lime : Colors.grey.shade600;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? ShellTokens.lime : ShellTokens.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? ShellTokens.lime
                        : ShellTokens.lime.withValues(alpha: 0.45),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ShellTokens.lime.withValues(alpha: selected ? 0.35 : 0.12),
                      blurRadius: selected ? 20 : 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 32,
                  color: selected ? ShellTokens.bg : ShellTokens.lime,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
