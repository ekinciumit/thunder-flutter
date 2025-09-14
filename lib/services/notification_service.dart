import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    // 1. İzinleri iste
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 2. FCM Token'ını al
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      // Token'ı Firestore'a kaydet
      await _authService.saveUserToken(token);
    }

    // 3. Gelen bildirimleri dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        // Burada uygulama içindeyken bir bildirim gösterebiliriz.
        // Örneğin bir SnackBar veya custom bir dialog.
      }
    });
  }
} 