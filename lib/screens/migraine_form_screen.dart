import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_models.dart';
import '../data/models.dart';
import '../data/patient_analytics_api.dart';
import '../data/storage.dart';
import '../services/app_services.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/head_pain_site_picker.dart';

class MigraineFormScreen extends StatefulWidget {
  const MigraineFormScreen({
    super.key,
    this.embedInShell = false,
    this.initialDurationHours,
    this.attackStartedAt,
  });

  /// When true, used inside [HomeScreen] shell without a duplicate app bar.
  final bool embedInShell;

  /// Pre-fills duration (hours) when opened after stopping the attack timer on Home.
  final int? initialDurationHours;

  /// When set (e.g. from attack timer), used as attack onset time instead of submit time.
  final DateTime? attackStartedAt;

  @override
  State<MigraineFormScreen> createState() => _MigraineFormScreenState();
}

class _MigraineFormScreenState extends State<MigraineFormScreen> {
  final _storage = SettingsStorage();

  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _intensityController = TextEditingController();
  final _ageController = TextEditingController();
  final _attackIdController = TextEditingController();

  String _location = HeadPainSitePicker.sites.first.id;
  String _character = 'Throbbing';

  int _nausea = 0;
  int _vomit = 0;
  int _phonophobia = 0;
  int _photophobia = 0;
  int _visual = 0;
  int _sensory = 0;
  int _dysphasia = 0;
  int _dysarthria = 0;
  int _vertigo = 0;
  int _tinnitus = 0;
  int _hypoacusis = 0;
  int _diplopia = 0;
  int _defect = 0;
  int _ataxia = 0;
  int _conscience = 0;
  int _paresthesia = 0;

  bool _submitting = false;
  MigraineApiResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draftJson = await _storage.readDraftAttack();
    final draft = MigraineAttack.fromDraftJson(draftJson);
    if (draft != null) {
      _durationController.text = draft.durationHours.toString();
      _intensityController.text = draft.intensity.toString();
      _ageController.text = draft.age?.toString() ?? '';
      _attackIdController.text = draft.attackId ?? '';
      if (draft.location.isNotEmpty) {
        _location = draft.location;
      }
      _character = draft.character;
      _nausea = draft.nausea;
      _vomit = draft.vomit;
      _phonophobia = draft.phonophobia;
      _photophobia = draft.photophobia;
      _visual = draft.visual;
      _sensory = draft.sensory;
      _dysphasia = draft.dysphasia;
      _dysarthria = draft.dysarthria;
      _vertigo = draft.vertigo;
      _tinnitus = draft.tinnitus;
      _hypoacusis = draft.hypoacusis;
      _diplopia = draft.diplopia;
      _defect = draft.defect;
      _ataxia = draft.ataxia;
      _conscience = draft.conscience;
      _paresthesia = draft.paresthesia;
    }

    if (widget.initialDurationHours != null && widget.initialDurationHours! > 0) {
      _durationController.text = '${widget.initialDurationHours}';
    }

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _saveDraft() async {
    final attack = _buildAttack(draftOnly: true);
    await _storage.saveDraftAttack(attack.toDraftJson());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }

  MigraineAttack _buildAttack({required bool draftOnly}) {
    return MigraineAttack(
      durationHours: int.tryParse(_durationController.text) ?? 0,
      frequencyPerMonth: 0,
      location: _location,
      character: _character,
      intensity: int.tryParse(_intensityController.text) ?? 0,
      nausea: _nausea,
      vomit: _vomit,
      phonophobia: _phonophobia,
      photophobia: _photophobia,
      visual: _visual,
      sensory: _sensory,
      dysphasia: _dysphasia,
      dysarthria: _dysarthria,
      vertigo: _vertigo,
      tinnitus: _tinnitus,
      hypoacusis: _hypoacusis,
      diplopia: _diplopia,
      defect: _defect,
      ataxia: _ataxia,
      conscience: _conscience,
      paresthesia: _paresthesia,
      patientId: null,
      attackId: _attackIdController.text.trim().isEmpty
          ? null
          : _attackIdController.text.trim(),
      age: int.tryParse(_ageController.text),
      timestamp: widget.attackStartedAt ?? DateTime.now(),
      summary: draftOnly ? null : _response?.summary,
      type: draftOnly ? null : _response?.predictedType,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!AppServices.auth.isAuthenticated ||
        AppServices.auth.currentUser?.role != UserRole.patient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in as a patient to save this attack to your record.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _response = null;
    });

    try {
      final baseUrl = await AppServices.auth.resolveApiBaseUrl();
      if (baseUrl.isEmpty) {
        throw Exception('API base URL is missing. Set it in Settings or .env.');
      }

      final patientId = await _storage.readPatientId();

      final attack = _buildAttack(draftOnly: false);
      final api = ApiClient(baseUrl: baseUrl);
      final result = await api.submitMigraineAttack(
        attack.copyWith(patientId: patientId),
      );

      clearPatientAnalyticsCache();
      await _storage.clearDraftAttack();

      if (!mounted) {
        return;
      }
      setState(() {
        _response = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attack saved to your clinic record.'),
          backgroundColor: Color(0xFFB6F36B),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _intensityController.dispose();
    _ageController.dispose();
    _attackIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final form = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
              SectionHeader(
                title: 'When did the attack happen?',
                subtitle: 'Help us understand your migraine pattern',
                illustrationIcon: Icons.schedule,
              ),
              const SizedBox(height: 8),
              _largeNumberField(
                controller: _durationController,
                label: 'Duration',
                unit: 'hours',
                description: 'How long did your attack last?',
              ),
              const SizedBox(height: 20),
              HeadPainSitePicker(
                value: _location,
                onChanged: (v) => setState(() => _location = v),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Describe the pain',
                subtitle: 'Help us understand your symptoms better',
                illustrationIcon: Icons.sentiment_dissatisfied,
              ),
              const SizedBox(height: 8),
              CustomDropdown(
                label: 'How does it feel?',
                value: _character,
                options: const ['Throbbing', 'Pressure'],
                onChanged: (value) {
                  setState(() {
                    _character = value;
                  });
                },
                description: 'Pulsing/throbbing or constant pressure?',
              ),
              const SizedBox(height: 16),
              IntensitySlider(
                value: int.tryParse(_intensityController.text) ?? 5,
                onChanged: (value) {
                  setState(() {
                    _intensityController.text = value.toString();
                  });
                },
                label: 'Pain Intensity',
                description: 'Rate your pain level',
              ),
              SectionHeader(
                title: 'Associated symptoms',
                subtitle: 'Select any symptoms you experienced',
                illustrationIcon: Icons.health_and_safety,
              ),
              const SizedBox(height: 8),
              SymptomToggle(
                label: 'Nausea',
                description: 'Do you feel nauseous?',
                value: _nausea == 1,
                onChanged: (value) {
                  setState(() {
                    _nausea = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Vomit',
                description: 'Do you feel like you might vomit?',
                value: _vomit == 1,
                onChanged: (value) {
                  setState(() {
                    _vomit = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Sound Sensitivity',
                description: 'Do loud sounds feel uncomfortable?',
                value: _phonophobia == 1,
                onChanged: (value) {
                  setState(() {
                    _phonophobia = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Light Sensitivity',
                description: 'Is bright light painful?',
                value: _photophobia == 1,
                onChanged: (value) {
                  setState(() {
                    _photophobia = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Visual Disturbances',
                description: 'Do you see flashes or spots?',
                value: _visual == 1,
                onChanged: (value) {
                  setState(() {
                    _visual = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Sensory Issues',
                description: 'Any numbness or tingling?',
                value: _sensory == 1,
                onChanged: (value) {
                  setState(() {
                    _sensory = value ? 1 : 0;
                  });
                },
              ),
              SectionHeader(
                title: 'Neurological symptoms',
                subtitle: 'These are more serious - report all you experience',
                illustrationIcon: Icons.psychology,
              ),
              const SizedBox(height: 8),
              SymptomToggle(
                label: 'Speech Difficulty',
                description: 'Dysphasia - trouble finding words?',
                value: _dysphasia == 1,
                onChanged: (value) {
                  setState(() {
                    _dysphasia = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Speech Slurring',
                description: 'Dysarthria - slurred speech?',
                value: _dysarthria == 1,
                onChanged: (value) {
                  setState(() {
                    _dysarthria = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Dizziness',
                description: 'Vertigo - spinning sensation?',
                value: _vertigo == 1,
                onChanged: (value) {
                  setState(() {
                    _vertigo = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Ringing in Ears',
                description: 'Tinnitus - hearing ringing?',
                value: _tinnitus == 1,
                onChanged: (value) {
                  setState(() {
                    _tinnitus = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Hearing Loss',
                description: 'Hypoacusis - reduced hearing?',
                value: _hypoacusis == 1,
                onChanged: (value) {
                  setState(() {
                    _hypoacusis = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Double Vision',
                description: 'Diplopia - seeing double?',
                value: _diplopia == 1,
                onChanged: (value) {
                  setState(() {
                    _diplopia = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Visual Field Defect',
                description: 'Blind spot or missing vision?',
                value: _defect == 1,
                onChanged: (value) {
                  setState(() {
                    _defect = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Loss of Coordination',
                description: 'Ataxia - difficulty balancing?',
                value: _ataxia == 1,
                onChanged: (value) {
                  setState(() {
                    _ataxia = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Loss of Consciousness',
                description: 'Did you lose consciousness?',
                value: _conscience == 1,
                onChanged: (value) {
                  setState(() {
                    _conscience = value ? 1 : 0;
                  });
                },
              ),
              SymptomToggle(
                label: 'Abnormal Sensations',
                description: 'Paresthesia - pins and needles?',
                value: _paresthesia == 1,
                onChanged: (value) {
                  setState(() {
                    _paresthesia = value ? 1 : 0;
                  });
                },
              ),
              SectionHeader(
                title: 'Optional details',
                subtitle: 'Help us personalize your care',
                illustrationIcon: Icons.info,
              ),
              const SizedBox(height: 8),
              _largeNumberField(
                controller: _ageController,
                label: 'Age',
                unit: 'years',
                description: 'Your age (optional)',
                isOptional: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _attackIdController,
                decoration: InputDecoration(
                  labelText: 'Attack ID (optional)',
                  hintText: 'e.g., migraine-2024-01',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MigraineButton(
                    onPressed: _submitting ? null : _submit,
                    label: 'Save to clinic record',
                    icon: Icons.cloud_upload,
                    isLoading: _submitting,
                  ),
                  const SizedBox(height: 12),
                  MigraineButton(
                    onPressed: _submitting ? null : _saveDraft,
                    label: 'Save as draft',
                    icon: Icons.save,
                    isOutlined: true,
                  ),
                ],
              ),
              if (_response != null) ...[
                const SizedBox(height: 24),
                ResultCard(
                  title: 'Prediction Result',
                  content: _response!.predictedType,
                  icon: Icons.verified,
                  backgroundColor: const Color(0xFFB6F36B).withValues(alpha: 0.1),
                ),
                const SizedBox(height: 12),
                ResultCard(
                  title: 'Summary',
                  content: _response!.summary,
                  icon: Icons.description,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      appBar: widget.embedInShell
          ? null
          : AppBar(
              title: const Text('Log migraine attack'),
              elevation: 0,
              backgroundColor: const Color(0xFF171B22),
            ),
      body: widget.embedInShell ? form : SafeArea(child: form),
    );
  }

  Widget _largeNumberField({
    required TextEditingController controller,
    required String label,
    required String unit,
    String? description,
    bool isOptional = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            description,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB6F36B),
                  ),
                  validator: (value) {
                    if (isOptional && (value == null || value.isEmpty)) {
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a number';
                    }
                    return null;
                  },
                ),
              ),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
