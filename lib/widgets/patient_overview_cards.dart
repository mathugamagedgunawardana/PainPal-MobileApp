import 'package:flutter/material.dart';

import '../theme/shell_tokens.dart';

const _kBg = Color(0xFF0F1218);
const _kSurface = Color(0xFF171B22);
const _kAccent = ShellTokens.limeMuted;

/// Single stat tile (Paynx / health-dashboard style).
class HealthMetricCard extends StatelessWidget {
  const HealthMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlighted = false,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlighted;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlighted
        ? _kAccent.withValues(alpha: 0.14)
        : const Color(0xFF1E232C);
    final border = highlighted
        ? _kAccent.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ShellTokens.cardRadius * 0.65),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: highlighted ? _kAccent : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: highlighted ? _kAccent : theme.colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-column grid of [HealthMetricCard]s with equal height rows.
class HealthMetricGrid extends StatelessWidget {
  const HealthMetricGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final left = children[i];
      final right = i + 1 < children.length ? children[i + 1] : null;
      if (right == null) {
        rows.add(SizedBox(height: 118, child: left));
      } else {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SizedBox(height: 118, child: left)),
                SizedBox(width: spacing),
                Expanded(child: SizedBox(height: 118, child: right)),
              ],
            ),
          ),
        );
      }
      if (i + 2 < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return Column(children: rows);
  }
}

/// Rounded section shell with optional title row.
class OverviewSectionCard extends StatelessWidget {
  const OverviewSectionCard({
    super.key,
    this.title,
    this.titleIcon,
    this.titleColor,
    this.subtitle,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  final String? title;
  final IconData? titleIcon;
  final Color? titleColor;
  final String? subtitle;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? _kSurface,
        borderRadius: BorderRadius.circular(ShellTokens.cardRadius * 0.75),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 22, color: titleColor ?? _kAccent),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Symptom likelihood chips inside a nested card.
class SymptomLikelihoodCard extends StatelessWidget {
  const SymptomLikelihoodCard({
    super.key,
    required this.title,
    required this.symptoms,
  });

  final String title;
  final List<({String name, String? percentLabel})> symptoms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (symptoms.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF252A34),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
                ),
                child: Text(
                  s.percentLabel != null ? '${s.name} ${s.percentLabel}' : s.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Compact trigger row card.
class TriggerChipCard extends StatelessWidget {
  const TriggerChipCard({super.key, required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, size: 20, color: _kAccent.withValues(alpha: 0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count×',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _kAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
