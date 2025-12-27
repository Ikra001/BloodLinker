import 'package:flutter/foundation.dart';

/// Custom logger that prefixes all logs with [BloodLinker] tag
/// This allows easy filtering in console: flutter logs | grep "BloodLinker"
class AppLogger {
  static const String _tag = '[BloodLinker]';

  static void log(String message) {
    if (kDebugMode) {
      debugPrint('$_tag $message');
    }
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('$_tag [ERROR] $message');
      if (error != null) {
        debugPrint('$_tag [ERROR] Details: $error');
      }
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_tag [INFO] $message');
    }
  }
}
