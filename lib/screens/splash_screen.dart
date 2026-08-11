import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../widgets/brand_logo.dart';
import '../widgets/loading_dots.dart';
import '../widgets/road_backdrop.dart';
import 'login_screen.dart';

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

  void _goToLogin() {
    // Guard against the tap and the timer both firing.
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondary) =>
            const LoginScreen(),
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
