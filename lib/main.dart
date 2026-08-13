import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AutoRescueApp());
}

class AutoRescueApp extends StatelessWidget {
  const AutoRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoRescue SW',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginScreen(),
        // Web-only: the admin portal isn't part of the mobile app, and
        // isn't linked from anywhere in the regular driver/mechanic UI —
        // reachable only by whoever's been given this URL directly.
        if (kIsWeb) '/admin': (BuildContext context) => const AdminLoginScreen(),
      },
    );
  }
}
