import 'package:flutter/material.dart';

import '../data/models.dart';

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

/// Possible Triggers section: preset chips + custom trigger input
class TriggerChipSection extends StatelessWidget {
  final List<String> selectedTriggers;
  final ValueChanged<List<String>> onChanged;
  final List<String> presetTriggers;

  const TriggerChipSection({
    super.key,
    required this.selectedTriggers,
    required this.onChanged,
    required this.presetTriggers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    void toggle(String trigger) {
      final next = List<String>.from(selectedTriggers);
      if (next.contains(trigger)) {
        next.remove(trigger);
      } else {
        next.add(trigger);
      }
      onChanged(next);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presetTriggers.map((trigger) {
              final selected = selectedTriggers.contains(trigger);
              return FilterChip(
                label: Text(trigger),
                selected: selected,
                onSelected: (_) => toggle(trigger),
                selectedColor: const Color(0xFFB6F36B).withValues(alpha: 0.3),
                checkmarkColor: const Color(0xFFB6F36B),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        _CustomTriggerField(
          existing: selectedTriggers,
          preset: presetTriggers,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CustomTriggerField extends StatefulWidget {
  final List<String> existing;
  final List<String> preset;
  final ValueChanged<List<String>> onChanged;

  const _CustomTriggerField({
    required this.existing,
    required this.preset,
    required this.onChanged,
  });

  @override
  State<_CustomTriggerField> createState() => _CustomTriggerFieldState();
}

class _CustomTriggerFieldState extends State<_CustomTriggerField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (widget.preset.any((t) => t.toLowerCase() == text.toLowerCase())) return;
    if (widget.existing.any((t) => t.toLowerCase() == text.toLowerCase())) return;
    widget.onChanged([...widget.existing, text]);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final customTriggers = widget.existing
        .where((t) => !widget.preset.any((p) => p.toLowerCase() == t.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Add custom trigger',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addCustom(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addCustom,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (customTriggers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: customTriggers.map((t) {
              return Chip(
                label: Text(t),
                onDeleted: () {
                  widget.onChanged(widget.existing.where((x) => x != t).toList());
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// Medications taken during attack: list with add/remove, effectiveness 1-5
class MedicationEntrySection extends StatelessWidget {
  final List<MedicationEntry> medications;
  final ValueChanged<List<MedicationEntry>> onChanged;
  final List<String> nameSuggestions;

  const MedicationEntrySection({
    super.key,
    required this.medications,
    required this.onChanged,
    required this.nameSuggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...medications.asMap().entries.map((entry) {
          final index = entry.key;
          final med = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MedicationRow(
              medication: med,
              suggestions: nameSuggestions,
              onChanged: (updated) {
                final next = List<MedicationEntry>.from(medications);
                next[index] = updated;
                onChanged(next);
              },
              onRemove: () {
                final next = List<MedicationEntry>.from(medications)..removeAt(index);
                onChanged(next);
              },
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            onChanged([
              ...medications,
              MedicationEntry(
                name: '',
                dosage: '',
                timeTaken: DateTime.now(),
                effectiveness: 3,
              ),
            ]);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add medication'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB6F36B),
            side: const BorderSide(color: Color(0xFFB6F36B)),
          ),
        ),
      ],
    );
  }
}

class _MedicationRow extends StatefulWidget {
  final MedicationEntry medication;
  final List<String> suggestions;
  final ValueChanged<MedicationEntry> onChanged;
  final VoidCallback onRemove;

  const _MedicationRow({
    required this.medication,
    required this.suggestions,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_MedicationRow> createState() => _MedicationRowState();
}

class _MedicationRowState extends State<_MedicationRow> {
  late TextEditingController _dosageController;
  TextEditingController? _nameController;

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.medication.dosage);
  }

  @override
  void didUpdateWidget(_MedicationRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medication.dosage != widget.medication.dosage) {
      _dosageController.text = widget.medication.dosage;
    }
  }

  @override
  void dispose() {
    _dosageController.dispose();
    super.dispose();
  }

  void _emit() {
    final name = _nameController?.text.trim() ?? widget.medication.name;
    widget.onChanged(MedicationEntry(
      name: name,
      dosage: _dosageController.text.trim(),
      timeTaken: widget.medication.timeTaken,
      effectiveness: widget.medication.effectiveness,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  initialValue: TextEditingValue(text: widget.medication.name),
                  optionsBuilder: (text) {
                    if (text.text.isEmpty) return widget.suggestions;
                    final lower = text.text.toLowerCase();
                    return widget.suggestions
                        .where((s) => s.toLowerCase().contains(lower))
                        .toList();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                    _nameController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Medication name',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () {
                                  onSelected(option);
                                  _emit();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(
              labelText: 'Dosage',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimePickerField(
                  label: 'Time taken',
                  value: widget.medication.timeTaken,
                  onChanged: (t) {
                    widget.onChanged(MedicationEntry(
                      name: _nameController?.text.trim() ?? widget.medication.name,
                      dosage: _dosageController.text.trim(),
                      timeTaken: t,
                      effectiveness: widget.medication.effectiveness,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Effectiveness', style: theme.textTheme.labelMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        icon: Icon(
                          star <= widget.medication.effectiveness
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          widget.onChanged(MedicationEntry(
                            name: _nameController?.text.trim() ?? widget.medication.name,
                            dosage: _dosageController.text.trim(),
                            timeTaken: widget.medication.timeTaken,
                            effectiveness: star,
                          ));
                        },
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time != null) {
          final dt = DateTime(value.year, value.month, value.day, time.hour, time.minute);
          onChanged(dt);
        }
      },
    );
  }
}

