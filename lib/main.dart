import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/session_shell.dart';
import 'services/app_services.dart';
import 'theme/shell_tokens.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  await AppServices.init();

  runApp(const PainpalApp());
}

class PainpalApp extends StatelessWidget {
  const PainpalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ShellTokens.lime,
      brightness: Brightness.dark,
    ).copyWith(
      primary: ShellTokens.lime,
      surface: ShellTokens.surface,
    );

    return MaterialApp(
      title: 'Painpal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: ShellTokens.bg,
        cardTheme: CardThemeData(
          color: ShellTokens.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShellTokens.cardRadius),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ShellTokens.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const SessionShell(),
    );
  }
}
