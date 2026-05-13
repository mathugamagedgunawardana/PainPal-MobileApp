import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/session_shell.dart';
import 'services/app_services.dart';
import 'theme/painpal_app_colors.dart';
import 'theme/painpal_theme_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await AppServices.init();

  runApp(const PainpalApp());
}

class PainpalApp extends StatelessWidget {
  const PainpalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppServices.theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'Painpal',
          debugShowCheckedModeBanner: false,
          theme: buildPainpalTheme(
            brightness: Brightness.light,
            c: PainpalAppColors.light,
          ),
          darkTheme: buildPainpalTheme(
            brightness: Brightness.dark,
            c: PainpalAppColors.dark,
          ),
          themeMode: AppServices.theme.themeMode,
          home: const SessionShell(),
        );
      },
    );
  }
}
