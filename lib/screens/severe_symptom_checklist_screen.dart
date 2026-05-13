import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/painpal_app_colors.dart';

/// Red-flag symptoms — educational; not a substitute for professional care.
class SevereSymptomChecklistScreen extends StatefulWidget {
  const SevereSymptomChecklistScreen({super.key});

  @override
  State<SevereSymptomChecklistScreen> createState() =>
      _SevereSymptomChecklistScreenState();
}

class _SevereSymptomChecklistScreenState
    extends State<SevereSymptomChecklistScreen> {
  final Map<String, bool> _checked = {};

  static const _items = <String>[
    'Sudden, severe “thunderclap” headache or the worst headache of your life',
    'Weakness, numbness, or paralysis on one side of the body',
    'Trouble speaking, understanding speech, or confusion that is new',
    'Vision loss, double vision, or new blind spots',
    'Fever with stiff neck or rash',
    'Head injury or fall before the headache started',
    'Seizure or loss of consciousness',
    'Headache that started very fast and peaked within seconds to a minute',
  ];

  Future<void> _dialEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the phone app. Dial your local emergency number.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;
    return Scaffold(
      backgroundColor: pp.bgTertiary,
      appBar: AppBar(
        title: const Text('Severe symptom checklist'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If you might be having an emergency',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red.shade100,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Call your local emergency number right away (e.g. 911, 999, 112). '
                  'This screen is only a reminder — it does not assess you.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade50,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _dialEmergency,
                  icon: const Icon(Icons.phone_in_talk),
                  label: const Text('Call 112 (tap if unsure — change in dialer)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Check anything that applies right now',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Even one of these with a bad headache can be serious. When in doubt, seek urgent care.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: pp.bgCard,
                borderRadius: BorderRadius.circular(12),
                child: CheckboxListTile(
                  value: _checked[t] ?? false,
                  onChanged: (v) => setState(() => _checked[t] = v ?? false),
                  title: Text(
                    t,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  checkColor: pp.textOnAccent,
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return pp.accentPrimary;
                    }
                    return null;
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'Checked anything? Consider urgent care or emergency services, '
            'especially if symptoms are new or worse than usual.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
