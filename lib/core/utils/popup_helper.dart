import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

void openDevicePopup(String deviceId) async {
  if (!kIsWeb) return;
  
  final currentUrl = Uri.base.toString().split('#')[0];
  final deviceUrl = Uri.parse('$currentUrl#/device/$deviceId');
  
  if (await canLaunchUrl(deviceUrl)) {
    await launchUrl(
      deviceUrl,
      mode: LaunchMode.externalApplication,
    );
  }
}
