import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics ve Analytics için merkezi servis.
class CrashReportingService {
  CrashReportingService._();

  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  static FirebaseCrashlytics? get _crashlytics =>
      _firebaseReady ? FirebaseCrashlytics.instance : null;

  static FirebaseAnalytics? get _analytics =>
      _firebaseReady ? FirebaseAnalytics.instance : null;

  static FirebaseAnalytics get analytics {
    final instance = _analytics;
    if (instance == null) {
      throw StateError('Firebase is not initialized');
    }
    return instance;
  }

  static Future<void> initialize() async {
    if (!_firebaseReady) return;
    await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);
    await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  static void installGlobalHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      _recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, source: 'ASYNC_ERROR', fatal: true);
      return true;
    };
  }

  static void _recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      debugPrint('❌ [FLUTTER_ERROR] ${details.exception}');
      debugPrint(details.stack?.toString() ?? '');
    }
    _crashlytics?.recordFlutterFatalError(details);
  }

  static void recordError(
    Object error,
    StackTrace stack, {
    String? source,
    bool fatal = false,
  }) {
    if (kDebugMode) {
      debugPrint('❌ [${source ?? 'ERROR'}] $error');
      debugPrint(stack.toString());
    }
    _crashlytics?.recordError(
      error,
      stack,
      reason: source,
      fatal: fatal,
    );
  }

  static void recordZoneError(Object error, StackTrace stack) {
    recordError(error, stack, source: 'ZONE_ERROR', fatal: true);
  }

  static Future<void> setUserId(String? userId) async {
    if (!_firebaseReady) return;
    await _crashlytics!.setUserIdentifier(userId ?? '');
    await _analytics!.setUserId(id: userId);
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_firebaseReady) return;
    await _analytics!.logEvent(name: name, parameters: parameters);
  }

  static Future<void> logScreenView(String screenName) async {
    if (!_firebaseReady) return;
    await _analytics!.logScreenView(screenName: screenName);
  }

  static Future<void> _enableCrashlyticsForDebugTest() async {
    if (kDebugMode && _crashlytics != null) {
      await _crashlytics!.setCrashlyticsCollectionEnabled(true);
    }
  }

  /// Debug/test: Crashlytics'e non-fatal kayıt gönderir.
  static Future<void> sendTestNonFatal() async {
    await _enableCrashlyticsForDebugTest();
    await logEvent('crashlytics_test_non_fatal');
    recordError(
      Exception('Crashlytics test non-fatal'),
      StackTrace.current,
      source: 'MANUAL_TEST',
    );
  }

  /// Debug/test: Bilinçli crash (yalnızca debug menüsünden).
  static Future<void> sendTestCrash() async {
    await _enableCrashlyticsForDebugTest();
    _crashlytics?.crash();
  }
}
