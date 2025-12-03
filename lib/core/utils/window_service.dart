import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: use dart:html for web, html_stub for other platforms
import 'dart:html' as html if (dart.library.html) 'dart:html';
import 'html_stub.dart' if (!dart.library.html) 'html_stub.dart' as html;

class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  /// Opens a device detail page in a new browser tab
  /// Only works on web platform
  void openDeviceInNewTab(String deviceId) {
    if (kIsWeb) {
      final currentUrl = html.window.location.href;
      final baseUrl = currentUrl.split('#')[0]; // Remove existing hash
      final deviceUrl = '$baseUrl#/device/$deviceId';
      
      // Open in new tab with _blank target
      html.window.open(deviceUrl, '_blank');
    }
  }

  /// Checks if the platform supports opening in new tabs
  bool get supportsNewTab => kIsWeb;
}
