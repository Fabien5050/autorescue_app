import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/location_service.dart';
import '../widgets/primary_button.dart';
import 'driver_main_dashboard.dart';

/// Onboarding step shown right after a driver's activation payment clears.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _radar.dispose();
    super.dispose();
  }

  bool _isRequesting = false;

  Future<void> _allowLocation() async {
    setState(() => _isRequesting = true);
    await LocationService.getCurrentPosition();
    if (!mounted) return;
    setState(() => _isRequesting = false);
    _goToDashboard();
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DriverMainDashboard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              SizedBox(
                width: 160,
                height: 160,
                child: AnimatedBuilder(
                  animation: _radar,
                  builder: (BuildContext context, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        for (final double delay in const <double>[0, 0.33, 0.66])
                          _RadarRing(progress: (_radar.value + delay) % 1.0),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'Help is just a tap away',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.heading,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To connect you with the nearest certified workshops in '
                'South-West Cameroon, we need to know your current location.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.slate),
              ),
              const Spacer(flex: 3),
              PrimaryButton(
                label: _isRequesting ? 'Requesting…' : 'Allow Location',
                color: AppColors.primaryBlue,
                trailingIcon: null,
                onPressed: _isRequesting ? null : _allowLocation,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _isRequesting ? null : _goToDashboard,
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.shield_outlined, size: 13, color: AppColors.slateLight),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your location data is encrypted and only used to '
                      'provide emergency assistance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: AppColors.slateLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final double size = 64 + progress * 96;
    return Opacity(
      opacity: (1 - progress).clamp(0.0, 1.0) * 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryBlue, width: 1.4),
        ),
      ),
    );
  }
}
