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
}
