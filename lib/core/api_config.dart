import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Resolves the AutoRecue backend's base URL for the current platform.
///
/// The Android emulator can't reach the host machine via `localhost` — it
/// has to go through the special `10.0.2.2` alias instead. Web (Chrome) and
/// desktop targets run on the host itself, so `localhost` works directly.
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8081';
    if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    return 'http://localhost:8081';
  }

  /// Uploaded-file URLs come back from the backend two ways depending on
  /// when they were uploaded: newer ones are already-absolute Cloudinary
  /// URLs, older ones are server-relative paths (e.g.
  /// `/uploads/profile-photos/x.jpg`) from before that switch and need
  /// [baseUrl] prefixed. This handles both without the caller needing to
  /// know which kind it has.
  static String? resolveFileUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}
