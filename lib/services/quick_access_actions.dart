import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/auth_models.dart';
import '../data/patient_appointments_api.dart';
import '../data/storage.dart';
import '../screens/severe_symptom_checklist_screen.dart';
import '../services/app_services.dart';
import '../theme/painpal_app_colors.dart';

// #region agent log
const _agentIngest =
    'http://127.0.0.1:7331/ingest/fd8dbf68-2237-4692-9a2f-a39d94c50740';
const _agentIngestEmu = 'http://10.0.2.2:7331/ingest/fd8dbf68-2237-4692-9a2f-a39d94c50740';

Future<void> _agentLog(
  String hypothesisId,
  String location,
  String message, {
  Map<String, Object?> data = const {},
}) async {
  final payload = <String, Object?>{
    'sessionId': 'a140b3',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  debugPrint('AGENT_LOG ${jsonEncode(payload)}');
  for (final base in [_agentIngestEmu, _agentIngest]) {
    try {
      await http
          .post(
            Uri.parse(base),
            headers: const {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'a140b3',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 400));
      break;
    } catch (_) {}
  }
}
// #endregion

/// Handlers for Home Quick Access (emergency, doctor, location, checklist).
abstract final class QuickAccessActions {
  static Future<void> openEmergencyContacts(BuildContext context) async {
    final storage = SettingsStorage();
    var list = await storage.readEmergencyContacts();

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.pp.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Emergency contacts',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stored on this device only. Tap to call.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      Text(
                        'No contacts yet. Add someone you trust.',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      )
                    else
                      ...list.map((e) {
                        return ListTile(
                          leading: Icon(
                            Icons.person_pin_circle_outlined,
                            color: ctx.pp.accentPrimary,
                          ),
                          title: Text(e.name.isEmpty ? 'Contact' : e.name),
                          subtitle: Text(e.phone),
                          trailing: Icon(
                            Icons.call,
                            color: ctx.pp.accentPrimary,
                          ),
                          onTap: () => _dialPhone(context, e.phone),
                        );
                      }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _agentLog(
                          'H3',
                          'quick_access_actions.dart:AddContact',
                          'onPressed_start',
                        );
                        final added = await _promptAddEmergencyContact(ctx);
                        await _agentLog(
                          'H3',
                          'quick_access_actions.dart:AddContact',
                          'prompt_returned',
                          data: {
                            'addedNull': added == null,
                            'phoneLen': added?.phone.length ?? 0,
                          },
                        );
                        if (added != null) {
                          list = [...list, added];
                          await storage.saveEmergencyContacts(list);
                          await _agentLog(
                            'H5',
                            'quick_access_actions.dart:AddContact',
                            'after_save_prefs',
                          );
                          setModal(() {});
                          await _agentLog(
                            'H3',
                            'quick_access_actions.dart:AddContact',
                            'after_setModal',
                          );
                        }
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add contact'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<EmergencyContactEntry?> _promptAddEmergencyContact(
    BuildContext context,
  ) async {
    await _agentLog(
      'H4',
      'quick_access_actions.dart:_promptAddEmergencyContact',
      'entry',
      data: {'contextMounted': context.mounted},
    );
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Add emergency contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+1 555 123 4567',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    await _agentLog(
      'H1',
      'quick_access_actions.dart:_promptAddEmergencyContact',
      'showDialog_complete',
      data: {'ok': ok},
    );
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    await _agentLog(
      'H2',
      'quick_access_actions.dart:_promptAddEmergencyContact',
      'before_dispose',
      data: {'nameLen': name.length, 'phoneLen': phone.length},
    );
    nameCtrl.dispose();
    await _agentLog(
      'H1',
      'quick_access_actions.dart:_promptAddEmergencyContact',
      'after_name_dispose',
    );
    phoneCtrl.dispose();
    await _agentLog(
      'H1',
      'quick_access_actions.dart:_promptAddEmergencyContact',
      'after_phone_dispose',
    );
    if (ok != true || phone.isEmpty) {
      return null;
    }
    return EmergencyContactEntry(name: name, phone: phone);
  }

  static Future<void> _dialPhone(BuildContext context, String raw) async {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) {
      return;
    }
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start a phone call on this device.')),
      );
    }
  }

  static Future<void> openCallDoctor(BuildContext context) async {
    if (AppServices.auth.currentUser?.role != UserRole.patient) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in as a patient to reach your care team from here.'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.pp.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: FutureBuilder(
              future: PatientAppointmentsApi().fetchLinkedDoctors(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text(
                    'Could not load your doctors. Check your connection.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  );
                }
                final doctors = snap.data ?? [];
                if (doctors.isEmpty) {
                  return Text(
                    'No linked doctors yet. Your clinic must activate a link before you can find them here.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your care team',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We don\'t store your doctor\'s direct line. Open Maps to the clinic or use Messages in the app.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView(
                        shrinkWrap: true,
                        children: doctors.map((d) {
                          final query = Uri.encodeComponent(
                            '${d.clinicName} ${d.clinicAddress ?? ''}'.trim(),
                          );
                          final mapsUri = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=$query',
                          );
                          return Card(
                            color: ctx.pp.bgSecondary,
                            child: ListTile(
                              title: Text(d.name),
                              subtitle: Text(
                                '${d.specialization}\n${d.clinicName}',
                              ),
                              isThreeLine: true,
                              trailing: Icon(Icons.map_outlined,
                                  color: ctx.pp.accentPrimary),
                              onTap: () async {
                                if (await canLaunchUrl(mapsUri)) {
                                  await launchUrl(
                                    mapsUri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static Future<void> shareLocation(BuildContext context) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is off. Enable it in system settings to share a map link.',
              ),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final url =
          'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      await Share.share(
        'My location (shared from PainPal): $url',
        subject: 'My location',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
          ),
        );
      }
    }
  }

  static void openSevereChecklist(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SevereSymptomChecklistScreen(),
      ),
    );
  }
}
