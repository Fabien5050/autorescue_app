import 'package:geolocator/geolocator.dart';

/// Real device GPS, replacing every hardcoded Buea coordinate that used to
/// stand in for "the user's current location" throughout the app.
class LocationService {
  LocationService._();

  /// Used only when permission is denied or a position can't be read —
  /// Buea, South-West Cameroon, matching this app's original placeholder
  /// so behavior degrades gracefully instead of crashing.
  static const double fallbackLatitude = 4.1550;
  static const double fallbackLongitude = 9.2415;

  /// Returns the current position, or null if permission was denied or
  /// location services are off.
  ///
  /// [requestIfNeeded] controls whether a not-yet-decided permission
  /// triggers the OS prompt — true (the default) is right for anything
  /// reached by explicit user action (opening a map screen, tapping "Allow
  /// Location"). Pass false for silent/background callers (e.g. a periodic
  /// timer) so a driver who's already said no isn't re-prompted every tick.
  static Future<Position?> getCurrentPosition({bool requestIfNeeded = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!requestIfNeeded) return null;
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Convenience for screens that just need *a* coordinate and would
  /// rather silently fall back than handle a null case.
  static Future<(double, double)> getCurrentLatLngOrFallback() async {
    final Position? position = await getCurrentPosition();
    if (position == null) return (fallbackLatitude, fallbackLongitude);
    return (position.latitude, position.longitude);
  }
}
