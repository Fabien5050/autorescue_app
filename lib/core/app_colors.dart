import 'package:flutter/material.dart';

/// Brand palette for AutoRescue SW.
///
/// The canonical design-system tokens are declared first. Every other
/// name in this class is a legacy alias kept so existing screens don't
/// need touching — they all resolve back to one of the tokens below, so
/// the whole app renders as a single consistent brand.
class AppColors {
  const AppColors._();

  // ---- Canonical design-system tokens ----------------------------------

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color secondaryCyan = Color(0xFF00ACC1);
  static const Color accentGreen = Color(0xFF43A047);
  static const Color warningOrange = Color(0xFFFB8C00);
  static const Color dangerRed = Color(0xFFE53935);
  static const Color screenBackground = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);

  // ---- Legacy aliases ----------------------------------------------------

  /// Headings and primary text.
  static const Color navy = primaryText;
  static const Color heading = primaryText;

  /// Call-to-action / active selection. Unified with [primaryBlue] so the
  /// whole app (login, registration, payment, dashboard) reads as one blue
  /// brand instead of switching between orange and blue per screen.
  static const Color orange = primaryBlue;
  static const Color orangeSoft = blueSoft;

  /// Driver registration accent — card icons and its CTA button.
  static const Color burntOrange = primaryBlue;
  static const Color burntOrangeSoft = blueSoft;

  /// Workshop registration CTA.
  static const Color safetyOrange = primaryBlue;

  /// Verification-workflow card accent.
  static const Color indigo = secondaryCyan;
  static const Color indigoSoft = Color(0xFFE0F7FA);

  /// Success / approved / verified / available states.
  static const Color success = accentGreen;
  static const Color successSoft = Color(0xFFE8F5E9);
  static const Color successText = Color(0xFF2E7D32);

  /// Warning / pending states.
  static const Color warning = warningOrange;
  static const Color warningSoft = Color(0xFFFFF3E0);

  /// Payment screen header.
  static const Color paymentHeader = primaryBlue;

  /// Emergency / delete / error accents.
  static const Color emergencyRed = dangerRed;
  static const Color emergencyAmber = warningOrange;

  /// Soft pill fill for tags like "Nearby", "Towing", "OPEN NOW".
  static const Color badgeSoft = Color(0xFFE3F2FD);

  /// Logo and secondary accents.
  static const Color blue = primaryBlue;
  static const Color blueSoft = Color(0xFFBBDEFB);

  static const Color slate = secondaryText;
  static const Color slateLight = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE0E0E0);
  static const Color surface = card;
  static const Color background = screenBackground;

  /// Vertical wash used behind the splash screen.
  static const List<Color> splashGradient = <Color>[
    Color(0xFFF4F7FB),
    Color(0xFFEDF2F8),
    Color(0xFFF7F9FC),
  ];
}
