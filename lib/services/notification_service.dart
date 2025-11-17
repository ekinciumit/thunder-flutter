import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../viewmodels/auth_viewmodel.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  AuthViewModel? _authViewModel; // Clean Architecture: AuthViewModel kullan
  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  
  // Notification tap callback - main.dart'da set edilecek
  Function(String chatId)? onNotificationTapped;

  /// NotificationService'i başlat
  /// 
  /// Clean Architecture: AuthViewModel kullanarak token kaydeder.
  Future<void> initialize(AuthViewModel authViewModel) async {
    _authViewModel = authViewModel;
    if (_initialized) {
      if (kDebugMode) {
        print('NotificationService.initialize: already initialized, skipping');
      }
      return;
    }
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

    // 2. FCM Token'ını al ve kaydet
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM Token: $token');
        }
        await _authViewModel?.saveUserToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM token fetch error: $e');
      }
    }

    // 2b. Token yenilendikçe kaydet
    _onTokenRefreshSub ??= _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      try {
        await _authViewModel?.saveUserToken(newToken);
      } catch (e) {
        if (kDebugMode) {
          print('FCM token save error: $e');
        }
      }
    });

    // 3. Gelen bildirimleri dinle (foreground)
    _onMessageSub ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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

    // 4. Bildirime dokunulduğunda (app açıkken)
    _onMessageOpenedSub ??= FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Notification tapped! Message data: ${message.data}');
      }
      _handleNotificationTap(message.data);
    });

    // 5. Uygulama kapalıyken bildirime dokunulduğunda kontrol et
    _checkInitialMessage();

    _initialized = true;
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('App opened from notification. Message data: ${initialMessage.data}');
      }
      _handleNotificationTap(initialMessage.data);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    if (chatId != null && onNotificationTapped != null) {
      onNotificationTapped!(chatId);
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _onMessageOpenedSub?.cancel();
  }
} 