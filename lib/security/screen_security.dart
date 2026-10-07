import 'package:flutter/services.dart';

/// Toggles Android FLAG_SECURE (blocks screenshots and hides the app preview
/// in the recent-apps switcher). Requires the MainActivity override in
/// android_overrides/. Silently does nothing if it isn't installed.
class ScreenSecurity {
  static const _channel = MethodChannel('quicknote/screen');
  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } catch (_) {}
  }
}
