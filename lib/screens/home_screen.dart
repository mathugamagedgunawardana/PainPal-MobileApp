import 'package:flutter/material.dart';

import '../widgets/chat_widget.dart';
import 'history_screen.dart';
import 'migraine_form_screen.dart';
import 'mri_upload_screen.dart';
import 'overview_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    OverviewScreen(),
    MigraineFormScreen(),
    MriUploadScreen(),
    HistoryScreen(),
    SettingsScreen(),
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
      bottomNavigationBar: NavigationBar(
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
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

