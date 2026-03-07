import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/theme_provider.dart';
import '../widgets/chat_widget.dart';
import 'history_screen.dart';
import 'mri_upload_screen.dart';
import 'overview_screen.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  void _navigateToTab(int index) {
    setState(() {
      _index = index;
    });
  }

  List<Widget> get _screens => [
    const OverviewScreen(),
    const MriUploadScreen(),
    TrackingScreen(
      onNavigateToLogAttack: () => _navigateToTab(2), // Self-reference for legacy support
    ),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getScreenTitle(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Theme toggle button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return RotationTransition(
                    turns: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(themeProvider.isDarkMode),
                  color: theme.colorScheme.primary,
                ),
              ),
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              onPressed: () {
                themeProvider.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          themeProvider.isDarkMode
                              ? 'Dark mode enabled'
                              : 'Light mode enabled',
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
            icon: Icon(Icons.image_search),
            label: 'MRI',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Tracking',
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

  String _getScreenTitle() {
    switch (_index) {
      case 0:
        return 'PainPal';
      case 1:
        return 'MRI Analysis';
      case 2:
        return 'Tracking';
      case 3:
        return 'History';
      case 4:
        return 'Settings';
      default:
        return 'PainPal';
    }
  }
}

