import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/auth_models.dart';
import '../data/patient_appointments_api.dart';
import '../services/app_services.dart';
import '../theme/painpal_app_colors.dart';
import '../widgets/custom_widgets.dart';

/// Schedule a visit with a doctor linked to the patient in MongoDB.
class ScheduleAppointmentScreen extends StatefulWidget {
  const ScheduleAppointmentScreen({super.key});

  @override
  State<ScheduleAppointmentScreen> createState() =>
      _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState extends State<ScheduleAppointmentScreen> {
  final _api = PatientAppointmentsApi();
  final _notesController = TextEditingController();

  List<LinkedDoctorOption> _doctors = [];
  List<PatientAppointmentRow> _existing = [];
  bool _initialLoad = true;
  bool _saving = false;
  String? _error;

  LinkedDoctorOption? _selectedDoctor;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _visitType = 'General visit';

  static const _visitTypes = [
    'General visit',
    'Follow-up',
    'Regular Check-up',
    'Initial Consultation',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initialLoad = true;
      _error = null;
    });
    try {
      if (!AppServices.auth.isAuthenticated ||
          AppServices.auth.currentUser?.role != UserRole.patient) {
        setState(() {
          _initialLoad = false;
          _error = 'Sign in with a patient account to schedule appointments.';
        });
        return;
      }
      final doctors = await _api.fetchLinkedDoctors();
      final appts = await _api.fetchAppointments();
      if (!mounted) {
        return;
      }
      setState(() {
        _doctors = doctors;
        _existing = appts;
        _selectedDoctor = doctors.isNotEmpty ? doctors.first : null;
        _initialLoad = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initialLoad = false;
        });
      }
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _submit() async {
    final doc = _selectedDoctor;
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No linked doctor available.')),
      );
      return;
    }
    final when = _combinedDateTime;
    if (!when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a future date and time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _api.createAppointment(
        doctorId: doc.doctorId,
        appointmentDate: when,
        appointmentType: _visitType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment scheduled'),
          backgroundColor: context.pp.accentSuccess,
        ),
      );
      await _bootstrap();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pp = context.pp;

    return Scaffold(
      backgroundColor: pp.bgTertiary,
      appBar: AppBar(
        title: const Text('📋 Schedule appointment'),
      ),
      body: _initialLoad && _doctors.isEmpty && _error == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _bootstrap,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: pp.accentWarning,
                        ),
                      ),
                    ),
                  SectionHeader(
                    title: 'Book with your care team',
                    subtitle:
                        'Only doctors linked to you in the clinic system appear here.',
                    illustrationIcon: Icons.event_available,
                  ),
                  const SizedBox(height: 20),
                  if (_doctors.isEmpty && !_initialLoad)
                    Text(
                      'No linked doctors yet. Your clinic must activate a doctor–patient link before you can schedule.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: pp.textSecondary,
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<LinkedDoctorOption>(
                      value: _selectedDoctor,
                      dropdownColor: pp.bgCard,
                      decoration: InputDecoration(
                        labelText: 'Doctor',
                        labelStyle: TextStyle(color: pp.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(color: pp.textPrimary),
                      items: _doctors
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '${d.name} · ${d.specialization}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDoctor = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(DateFormat.yMMMd().format(_date)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule, size: 18),
                            label: Text(_time.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _visitType,
                      dropdownColor: pp.bgCard,
                      decoration: InputDecoration(
                        labelText: 'Visit type',
                        labelStyle: TextStyle(color: pp.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(color: pp.textPrimary),
                      items: _visitTypes
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _visitType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: pp.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Notes for the clinic (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    MigraineButton(
                      onPressed: _saving ? null : _submit,
                      label: 'Request appointment',
                      icon: Icons.send,
                      isLoading: _saving,
                    ),
                  ],
                  if (_existing.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    Text(
                      'Your appointments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: pp.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._existing.map(
                      (a) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: pp.bgCard,
                        child: ListTile(
                          title: Text(
                            a.doctorName,
                            style: TextStyle(
                              color: pp.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat.yMMMd().add_jm().format(a.appointmentDate.toLocal())} · ${a.appointmentType}\n${a.status}',
                            style: TextStyle(color: pp.textSecondary),
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
