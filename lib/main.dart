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

  static bool get _isAdminRoute {
    if (!kIsWeb) return false;
    final String fragment = Uri.base.fragment.toLowerCase().trim();
    final String path = Uri.base.path.toLowerCase().trim();
    return fragment.startsWith('/admin') ||
           fragment == 'admin' ||
           path.endsWith('/admin') ||
           path.endsWith('/admin/');
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _isAdminRoute;

    return MaterialApp(
      title: 'AutoRescue SW',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light,
      home: isAdmin ? const AdminLoginScreen() : const SplashScreen(),
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginScreen(),
        '/admin': (BuildContext context) => const AdminLoginScreen(),
      },
    );
  }
}
