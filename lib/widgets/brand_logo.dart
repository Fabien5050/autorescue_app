import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Blue rounded-square mark holding the car + wrench glyphs.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Soft halo plate behind the mark.
          Container(
            width: size * 1.32,
            height: size * 1.32,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(size * 0.36),
            ),
          ),
          // Small orbiting dots, as in the mockup corners.
          Positioned(top: size * 0.06, right: size * 0.08, child: _dot(size * 0.12)),
          Positioned(bottom: size * 0.14, left: size * 0.1, child: _dot(size * 0.09)),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(size * 0.26),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.directions_car_filled,
                  color: Colors.white,
                  size: size * 0.36,
                ),
                SizedBox(height: size * 0.04),
                Icon(Icons.build, color: Colors.white, size: size * 0.22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double diameter) => Container(
        width: diameter,
        height: diameter,
        decoration: const BoxDecoration(
          color: AppColors.blueSoft,
          shape: BoxShape.circle,
        ),
      );
}

/// "AutoRescue SW" wordmark: navy body, blue suffix.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 30});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        children: const <TextSpan>[
          TextSpan(text: 'AutoRescue', style: TextStyle(color: AppColors.navy)),
          TextSpan(text: ' SW', style: TextStyle(color: AppColors.blue)),
        ],
      ),
    );
  }
}
