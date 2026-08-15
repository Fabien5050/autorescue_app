import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/app_navigator.dart';
import 'core/app_theme.dart';
import 'core/notification_service.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Mobile-only, same as voice calling — flutter_local_notifications has no
  // web platform implementation.
  if (!kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init();
  }
  runApp(const AutoRescueApp());
}

class AutoRescueApp extends StatelessWidget {
  const AutoRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp's implicit "restore the initial route from the URL"
    // behavior isn't reliable for a cold page load under hash-based web
    // routing (e.g. GitHub Pages) — it was falling back to `home`
    // (SplashScreen) even when the browser was pointed at .../#/admin,
    // which then auto-navigated to the regular driver/mechanic login after
    // its timer. Reading Uri.base directly sidesteps that: it reflects the
    // real browser URL the page was loaded with, so the admin entry point
    // is chosen correctly regardless of how Navigator resolves route names.
    final bool isAdminEntry = kIsWeb && Uri.base.fragment.startsWith('/admin');

    return MaterialApp(
      title: 'AutoRescue SW',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      theme: AppTheme.light,
      home: isAdminEntry ? const AdminLoginScreen() : const SplashScreen(),
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
