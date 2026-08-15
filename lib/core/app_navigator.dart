import 'package:flutter/material.dart';

/// Global navigator access for code that isn't itself a widget with a
/// [BuildContext] — currently just notification-tap routing, which needs to
/// push a screen regardless of whatever happens to be on screen at the time.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;
}
