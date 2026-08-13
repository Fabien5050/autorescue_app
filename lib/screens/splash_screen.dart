import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/session.dart';
import '../widgets/brand_logo.dart';
import '../widgets/loading_dots.dart';
import '../widgets/road_backdrop.dart';
import 'driver_main_dashboard.dart';
import 'login_screen.dart';
import 'workshop_owner/workshop_owner_main.dart';

/// Branded splash. Auto-advances after [_holdDuration], or immediately on tap.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Duration _holdDuration = Duration(seconds: 3);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _navigated = false;
  final Future<void> _restoreFuture = Session.instance.restore();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen._holdDuration, _goToLogin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _goToLogin() async {
    // Guard against the tap and the timer both firing.
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();

    await _restoreFuture;
    if (!mounted) return;

    // An ADMIN session only ever belongs on the web-only /admin route, not
    // this driver/mechanic entry point — treat it as signed out here rather
    // than dropping an admin into the driver dashboard.
    if (Session.instance.role == 'ADMIN') {
      await Session.instance.clear();
      if (!mounted) return;
    }

    final Widget destination = !Session.instance.isLoggedIn
        ? const LoginScreen()
        : Session.instance.role == 'MECHANIC'
            ? const WorkshopOwnerMain()
            : const DriverMainDashboard();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondary) =>
            destination,
        transitionsBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondary, Widget child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _goToLogin,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.splashGradient,
            ),
          ),
          child: Stack(
            children: <Widget>[
              const RoadBackdrop(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: <Widget>[
                        const Spacer(flex: 3),
                        const BrandLogo(),
                        const SizedBox(height: 18),
                        const BrandWordmark(),
                        const SizedBox(height: 14),
                        const _RegionLabel(),
                        const SizedBox(height: 34),
                        const LoadingDots(),
                        const Spacer(flex: 4),
                        Text(
                          'Find nearby car repair help\ninstantly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _TrustFooter(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "SOUTH-WEST REGION" between two hairline rules.
class _RegionLabel extends StatelessWidget {
  const _RegionLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const _Rule(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'SOUTH-WEST REGION',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: AppColors.blue.withValues(alpha: 0.85),
            ),
          ),
        ),
        const _Rule(),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 1,
      color: AppColors.slateLight.withValues(alpha: 0.5),
    );
  }
}

class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.slate.withValues(alpha: 0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.verified_user_outlined, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          'TRUSTED ASSISTANCE NETWORK',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: color,
          ),
        ),
      ],
    );
  }
}
