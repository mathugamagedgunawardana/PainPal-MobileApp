import 'package:flutter/material.dart';

import '../theme/painpal_app_colors.dart';

const _kDockDark = Color(0xFF1C1B2E);

/// Five-slot dock — light theme uses a dark bar + white glyphs (mood / wellness app refs).
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
    final pp = context.pp;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final dockBg = isLight ? _kDockDark : pp.bgCard;
    final borderCol =
        isLight ? Colors.white.withValues(alpha: 0.08) : pp.borderDefault;
    final shadow = isLight
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : pp.shadowCard;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      child: Container(
        height: _dockHeight,
        decoration: BoxDecoration(
          color: dockBg,
          borderRadius: BorderRadius.circular(PainpalRadii.dock),
          border: Border.all(color: borderCol),
          boxShadow: shadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SideSlot(
              selected: currentIndex == 0,
              emoji: '🏠',
              label: 'Home',
              onTap: () => onSelect(0),
              lightDock: isLight,
            ),
            _SideSlot(
              selected: currentIndex == 1,
              emoji: '📊',
              label: 'Stats',
              onTap: () => onSelect(1),
              lightDock: isLight,
            ),
            _CenterPill(
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
              lightDock: isLight,
            ),
            _SideSlot(
              selected: currentIndex == 3,
              emoji: '📅',
              label: 'History',
              onTap: () => onSelect(3),
              lightDock: isLight,
            ),
            _SideSlot(
              selected: currentIndex == 4,
              emoji: '🧬',
              label: 'MRI',
              onTap: () => onSelect(4),
              lightDock: isLight,
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
    required this.emoji,
    required this.label,
    required this.onTap,
    required this.lightDock,
  });

  final bool selected;
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool lightDock;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final Color active;
    final Color idle;
    if (lightDock) {
      active = Colors.white;
      idle = Colors.white.withValues(alpha: 0.45);
    } else {
      active = pp.accentPrimary;
      idle = pp.textTertiary;
    }
    final color = selected ? active : idle;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 22 : 20)),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterPill extends StatelessWidget {
  const _CenterPill({
    required this.selected,
    required this.onTap,
    required this.lightDock,
  });

  final bool selected;
  final VoidCallback onTap;
  final bool lightDock;

  @override
  Widget build(BuildContext context) {
    final pp = context.pp;
    final Color fill;
    final Color iconCol;
    final List<BoxShadow> glow;
    if (lightDock) {
      fill = Colors.white;
      iconCol = _kDockDark;
      glow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      fill = pp.accentPrimary;
      iconCol = pp.textOnAccent;
      glow = pp.shadowElevated;
    }

    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(PainpalRadii.pill),
                  boxShadow: glow,
                  border: lightDock
                      ? null
                      : Border.all(
                          color: selected
                              ? pp.accentPrimary
                              : pp.borderDefault,
                        ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 30,
                  color: iconCol,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
