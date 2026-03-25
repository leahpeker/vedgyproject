import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Platform detection utilities for cross-platform behavior
class PlatformUtils {
  /// True if running on web platform
  static bool get isWeb => kIsWeb;

  /// True if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// True if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// True if running on any mobile platform (iOS or Android)
  static bool get isMobile => isIOS || isAndroid;

  /// True if running on desktop (macOS, Windows, Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
}
