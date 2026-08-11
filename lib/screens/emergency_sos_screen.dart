import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/workshop.dart';
import '../widgets/stylized_map.dart';

/// SOS tab: fastest path to sharing location and calling the nearest help.
class EmergencySosScreen extends StatelessWidget {
  const EmergencySosScreen({super.key});

  void _shareLocation(BuildContext context) {
    // Hook the real geolocation share / dispatch call in here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text('Sharing your location with nearby workshops…'),
      ),
    );
  }

  void _call(BuildContext context, String label) {
    // Hook a real tel: launcher (e.g. url_launcher) in here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.navy,
        behavior: SnackBarBehavior.floating,
        content: Text('Calling $label…'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const _EmergencyHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ShareLocationCard(onTap: () => _shareLocation(context)),
                  const SizedBox(height: 22),
                  const Text(
                    'Nearest Workshops',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap call for immediate assistance',
                    style: TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < emergencyNearestWorkshops.length; i++) ...<Widget>[
                    _NearestWorkshopRow(
                      workshop: emergencyNearestWorkshops[i],
                      urgent: i == 0,
                      onCall: () => _call(context, emergencyNearestWorkshops[i].name),
                    ),
                    if (i != emergencyNearestWorkshops.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 20),
                  StylizedMap(
                    height: 150,
                    pins: const <MapPin>[
                      MapPin(alignment: Alignment.center, pulsing: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'YOUR LOCATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Other Emergency Contacts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ContactPill(
                          icon: Icons.local_police_outlined,
                          label: 'Police (117)',
                          onTap: () => _call(context, 'Police'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ContactPill(
                          icon: Icons.medical_services_outlined,
                          label: 'Ambulance (119)',
                          onTap: () => _call(context, 'Ambulance'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyHeader extends StatelessWidget {
  const _EmergencyHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: const Color(0xFFFEF2F2),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EMERGENCY HELP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergencyRed,
                  ),
                ),
                Text(
                  'SOUTH-WEST CAMEROON REGION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.emergencyRed.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareLocationCard extends StatelessWidget {
  const _ShareLocationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBlue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.my_location, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 10),
              const Text(
                'SHARE MY LOCATION',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Currently near Mile 17, Buea',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearestWorkshopRow extends StatelessWidget {
  const _NearestWorkshopRow({
    required this.workshop,
    required this.urgent,
    required this.onCall,
  });

  final Workshop workshop;
  final bool urgent;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final Color callColor = urgent ? AppColors.emergencyRed : AppColors.primaryBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (workshop.isOpenNow)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Flexible(
                      child: Text(
                        workshop.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  workshop.distanceLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: callColor,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onCall,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.call, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'CALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPill extends StatelessWidget {
  const _ContactPill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.badgeSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
