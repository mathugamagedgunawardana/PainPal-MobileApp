import 'package:flutter/material.dart';

/// Soft palette matching reference: pastel blues, warm accents, cream
class AppIllustrationColors {
  static const Color pastelBlue = Color(0xFFB3D9F5);
  static const Color pastelBlueDark = Color(0xFF5B9BD5);
  static const Color softBlueBg = Color(0xFFE8F4FD);
  static const Color warmOrange = Color(0xFFFFB74D);
  static const Color warmGreen = Color(0xFF81C784);
  static const Color softPurple = Color(0xFFB39DDB);
  static const Color cream = Color(0xFFFFF8E1);
  static const Color white = Color(0xFFFFFFFF);
}

/// Hero section: gradient strip + white card with circular illustration (safe: no CustomPaint)
class WelcomeHeroIllustration extends StatelessWidget {
  const WelcomeHeroIllustration({
    super.key,
    this.size = 140,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppIllustrationColors.pastelBlueDark : AppIllustrationColors.pastelBlueDark;
    final bg = isDark ? primary.withValues(alpha: 0.25) : AppIllustrationColors.softBlueBg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.health_and_safety_rounded,
            size: size * 0.5,
            color: primary,
          ),
          // Decorative small circles (like thought bubbles)
          Positioned(
            top: size * 0.08,
            right: size * 0.12,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: AppIllustrationColors.warmOrange.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.15,
            left: size * 0.08,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: AppIllustrationColors.warmGreen.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full hero block: gradient background + white card + illustration + text
class WelcomeHeroSection extends StatelessWidget {
  const WelcomeHeroSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  AppIllustrationColors.pastelBlueDark.withValues(alpha: 0.15),
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppIllustrationColors.softBlueBg,
                  theme.scaffoldBackgroundColor,
                ],
              ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const WelcomeHeroIllustration(size: 120),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Empty state illustration: large rounded area with icon (e.g. tracking, history)
class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 100,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = iconColor ?? AppIllustrationColors.pastelBlueDark;
    final bg = backgroundColor ?? (isDark ? color.withValues(alpha: 0.2) : AppIllustrationColors.softBlueBg);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Tip/wellness card with small illustration (e.g. sleep, relax)
class TipCardIllustration extends StatelessWidget {
  const TipCardIllustration({
    super.key,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size = 56,
  });

  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = iconColor ?? AppIllustrationColors.pastelBlueDark;
    final bg = backgroundColor ?? (isDark ? color.withValues(alpha: 0.2) : AppIllustrationColors.softBlueBg);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

/// Checklist-style step icon (numbered circle with small icon inside)
class StepIllustrationIcon extends StatelessWidget {
  const StepIllustrationIcon({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppIllustrationColors.pastelBlueDark.withValues(alpha: 0.3) : AppIllustrationColors.softBlueBg);
    final color = iconColor ?? AppIllustrationColors.pastelBlueDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Feature card with illustration icon (rounded square background)
class FeatureIllustrationIcon extends StatelessWidget {
  const FeatureIllustrationIcon({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 52,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? AppIllustrationColors.pastelBlueDark.withValues(alpha: 0.25) : AppIllustrationColors.softBlueBg);
    final color = iconColor ?? AppIllustrationColors.pastelBlueDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}
