import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import 'dart:convert';

/// Local data source interface for authentication
/// 
/// Bu interface SOLID prensiplerinden Interface Segregation Principle'a uyar:
/// - Sadece local (cache) işlemlerinden sorumlu
/// - Remote işlemler ayrı interface'de
/// 
/// ŞU AN: Bu interface sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu interface'i implement edeceğiz

abstract class AuthLocalDataSource {
  /// Kullanıcı profilini cache'e kaydet
  Future<void> cacheUser(UserModel user);
  
  /// Cache'den kullanıcı profilini getir
  /// 
  /// Returns: UserModel if found, null otherwise
  Future<UserModel?> getCachedUser();
  
  /// Cache'i temizle
  Future<void> clearCache();
}

/// SharedPreferences implementation of AuthLocalDataSource
/// 
/// Bu sınıf kullanıcı profilini local storage'da saklar.
/// Mevcut kodda cache yok, bu yeni bir özellik.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;
  static const String _cachedUserKey = 'cached_user';
  
  AuthLocalDataSourceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toMap());
      await _prefs.setString(_cachedUserKey, userJson);
    } catch (e) {
      throw CacheException('Kullanıcı cache\'lenirken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = _prefs.getString(_cachedUserKey);
      if (userJson == null) return null;
      
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      // UserModel.fromMap için uid gerekiyor, map'te olmalı
      final uid = userMap['uid'] as String?;
      if (uid == null) return null;
      
      return UserModel.fromMap(userMap, uid);
    } catch (e) {
      // Cache hatası durumunda null döndür (mevcut kod mantığı)
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_cachedUserKey);
    } catch (e) {
      throw CacheException('Cache temizlenirken bir hata oluştu: ${e.toString()}');
    }
  }
}

