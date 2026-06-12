import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Uygulama izinleri için merkezi yardımcı.
class AppPermissionService {
  AppPermissionService._();

  /// Android 13+ bildirim izni + iOS'ta no-op (FCM kendi akışını kullanır).
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    if (kDebugMode) {
      debugPrint('📣 [PERMISSION] notification → $result');
    }
    return result.isGranted;
  }

  static Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return Permission.notification.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (kDebugMode) {
      debugPrint('🎙️ [PERMISSION] microphone → $status');
    }
    return status.isGranted;
  }
}
