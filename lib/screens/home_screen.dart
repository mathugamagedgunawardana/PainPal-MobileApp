import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../widgets/chat_widget.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'migraine_form_screen.dart';
import 'mri_upload_screen.dart';
import 'log_attack_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSignedOut});

  /// Called after local credentials are cleared (e.g. from Settings).
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'You will need to sign in again to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await AppServices.auth.logout();
    widget.onSignedOut();
  }

  late final List<Widget> _screens = [
    const LogAttackScreen(),
    const MigraineFormScreen(),
    const MriUploadScreen(),
    const HistoryScreen(),
    const AnalyticsScreen(),
    SettingsScreen(onSignedOut: widget.onSignedOut),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_index]),
      floatingActionButton: ChatButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ChatDialog(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: const Color(0xFF171B22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmSignOut(context),
                    icon: Icon(Icons.logout, size: 20, color: Colors.redAccent.shade100),
                    label: Text(
                      'Sign out',
                      style: TextStyle(color: Colors.redAccent.shade100),
                    ),
                  ),
                ],
              ),
            ),
          ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) {
              setState(() {
                _index = value;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note),
                label: 'Log attack',
              ),
              NavigationDestination(
                icon: Icon(Icons.image_search),
                label: 'MRI upload',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

