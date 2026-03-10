import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'data/app_theme.dart';
import 'data/auth_service.dart';
import 'data/notification_service.dart';
import 'data/patient_data_service.dart';
import 'data/theme_provider.dart';
import 'screens/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize local notifications in background so app opens immediately
  NotificationService.instance.initialize();

  // Initialize AuthService before building the widget tree
  final authService = AuthService();
  await authService.initialize();

  runApp(PainpalApp(authService: authService));
}

class PainpalApp extends StatelessWidget {
  const PainpalApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        Provider<AuthService>.value(value: authService),
        ProxyProvider<AuthService, PatientDataService>(
          update: (context, auth, previous) =>
              PatientDataService(authService: auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Painpal',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const LandingScreen(),
          );
        },
      ),
    );
  }
}
