import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PainpalApp());
}

class PainpalApp extends StatelessWidget {
  const PainpalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB6F36B),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Painpal',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1218),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171B22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
