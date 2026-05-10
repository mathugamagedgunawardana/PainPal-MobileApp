import 'package:flutter/material.dart';

import '../services/app_services.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';

/// Chooses landing vs main shell from [AppServices.auth]; hosts login as a route.
class SessionShell extends StatefulWidget {
  const SessionShell({super.key});

  @override
  State<SessionShell> createState() => _SessionShellState();
}

class _SessionShellState extends State<SessionShell> {
  late bool _signedIn;

  @override
  void initState() {
    super.initState();
    _signedIn = AppServices.auth.isAuthenticated;
  }

  void _onSignedIn() {
    setState(() => _signedIn = true);
  }

  void _onSignedOut() {
    setState(() => _signedIn = false);
  }

  Future<void> _openLogin(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (ctx) => const LoginScreen(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (ok == true) {
      _onSignedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn) {
      return HomeScreen(onSignedOut: _onSignedOut);
    }
    return LandingScreen(
      onSignIn: () => _openLogin(context),
    );
  }
}
