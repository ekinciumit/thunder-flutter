import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Feedback Service
/// 
/// Kullanıcı geri bildirimlerini Firebase'e gönderir.
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Geri bildirim türleri
  static const String typeBug = 'bug';
  static const String typeSuggestion = 'suggestion';
  static const String typeGeneral = 'general';
  
  /// Geri bildirim gönder
  Future<bool> submitFeedback({
    required String message,
    String type = typeGeneral,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      
      await _firestore.collection('feedbacks').add({
        'userId': user?.uid,
        'userEmail': email ?? user?.email,
        'message': message,
        'type': type,
        'platform': _getPlatformName(),
        'appVersion': '1.0.0',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
      });
      
      if (kDebugMode) {
        debugPrint('✅ Geri bildirim başarıyla gönderildi');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Geri bildirim gönderilemedi: $e');
      }
      return false;
    }
  }
  
  /// Platform adını al
  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
  
  /// Kullanıcının geri bildirimlerini getir (opsiyonel - admin paneli için)
  Future<List<Map<String, dynamic>>> getUserFeedbacks() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('feedbacks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
