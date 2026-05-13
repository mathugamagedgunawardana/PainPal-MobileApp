import 'package:flutter/material.dart';

import '../theme/painpal_app_colors.dart';
import '../widgets/painpal_illustrations.dart';

/// First screen for signed-out users: brand intro and entry to [LoginScreen].
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pp = context.pp;

    return Scaffold(
      backgroundColor: pp.bgTertiary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Painpal',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: pp.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              PainpalMoodCollage(
                height: MediaQuery.sizeOf(context).height * 0.28,
                borderRadius: PainpalRadii.cardBubble,
              ),
              const SizedBox(height: 28),
              Text(
                'Not sure how\nyou\'re feeling?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: pp.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Track migraines with friendly visuals — patterns, history, and care in one calm place.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                label: const Text(
                  'Let\'s go',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(PainpalRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in with your patient account. Set API URL in Settings anytime.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: pp.textTertiary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
