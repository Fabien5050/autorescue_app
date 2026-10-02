import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/app_navigator.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoRescueApp());
  if (!kIsWeb) unawaited(NotificationService.init());
}

class AutoRescueApp extends StatelessWidget {
  const AutoRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Detects whether browser URL points to the admin portal path or fragment (#/admin).
    final bool isAdminEntry = kIsWeb && (
      Uri.base.fragment.startsWith('/admin') ||
      Uri.base.path.endsWith('/admin') ||
      Uri.base.path.endsWith('/admin/')
    );

    return MaterialApp(
      title: 'AutoRescue SW',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light,
      home: isAdminEntry ? const AdminLoginScreen() : const SplashScreen(),
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginScreen(),
        '/admin': (BuildContext context) => const AdminLoginScreen(),
      },
    );
  }
}
