import 'package:flutter/material.dart';

/// A large, easy-to-tap slider for migraine patients
class IntensitySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final String label;
  final String description;

  const IntensitySlider({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade700),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1', style: theme.textTheme.bodySmall),
                    Text('10', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8,
                    activeTrackColor: const Color(0xFFB6F36B),
                    inactiveTrackColor: Colors.grey.shade700,
                    thumbColor: const Color(0xFFB6F36B),
                    overlayColor: const Color(0xFFB6F36B).withValues(alpha: 0.3),
                    thumbShape: const RoundSliderThumbShape(
                      elevation: 4,
                      enabledThumbRadius: 14,
                    ),
                  ),
                  child: Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: value.toDouble(),
                    onChanged: (val) => onChanged(val.toInt()),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFB6F36B),
                    fontWeight: FontWeight.bold,
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

/// Binary toggle button for symptoms
class SymptomToggle extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SymptomToggle({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFB6F36B).withValues(alpha: 0.1) : null,
        border: Border.all(
          color: value ? const Color(0xFFB6F36B) : Colors.grey.shade700,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 32,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFFB6F36B)
                      : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      left: value ? 24 : 2,
                      top: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: value
                            ? const Icon(Icons.check,
                                color: Color(0xFF0F1218), size: 16)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large button styled for migraine patients
class MigraineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;

  const MigraineButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: (isLoading || onPressed == null) ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.check),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: Color(0xFFB6F36B), width: 2),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Icon(icon ?? Icons.check),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB6F36B),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }
}

/// Result card for displaying API responses
class ResultCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color? backgroundColor;

  const ResultCard({
    Key? key,
    required this.title,
    required this.content,
    required this.icon,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF171B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB6F36B), width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB6F36B), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFB6F36B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Section header with illustration
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? illustrationIcon;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.illustrationIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (illustrationIcon != null)
            Icon(
              illustrationIcon,
              size: 40,
              color: const Color(0xFFB6F36B),
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dropdown with better styling for dark theme
class CustomDropdown extends StatelessWidget {
  final String label;
  final String? description;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const CustomDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        )),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF171B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade700),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF171B22),
              items: options
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: (selection) {
                if (selection != null) {
                  onChanged(selection);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

