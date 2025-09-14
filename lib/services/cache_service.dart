import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

class CacheService {
  static const String _messagesKey = 'cached_messages_';
  static const String _lastUpdateKey = 'last_update_';
  static const int _cacheExpiryHours = 24; // 24 saat cache süresi

  /// Mesajları cache'e kaydet
  static Future<void> cacheMessages(String chatId, List<MessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((msg) => msg.toMap()).toList();
      final messagesString = jsonEncode(messagesJson);
      
      await prefs.setString('$_messagesKey$chatId', messagesString);
      await prefs.setInt('$_lastUpdateKey$chatId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Debug: Error caching messages: $e
    }
  }

  /// Cache'den mesajları getir
  static Future<List<MessageModel>> getCachedMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesString = prefs.getString('$_messagesKey$chatId');
      final lastUpdate = prefs.getInt('$_lastUpdateKey$chatId');
      
      if (messagesString == null || lastUpdate == null) {
        return [];
      }

      // Cache süresi kontrolü
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      final now = DateTime.now();
      if (now.difference(cacheTime).inHours > _cacheExpiryHours) {
        // Cache süresi dolmuş, temizle
        await clearCache(chatId);
        return [];
      }

      final messagesJson = jsonDecode(messagesString) as List;
      return messagesJson.map((json) => MessageModel.fromMap(json, '')).toList();
    } catch (e) {
      // Debug: Error getting cached messages: $e
      return [];
    }
  }

  /// Cache'i temizle
  static Future<void> clearCache(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_messagesKey$chatId');
      await prefs.remove('$_lastUpdateKey$chatId');
    } catch (e) {
      // Debug: Error clearing cache: $e
    }
  }

  /// Tüm cache'i temizle
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_messagesKey) || key.startsWith(_lastUpdateKey)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Debug: Error clearing all cache: $e
    }
  }

  /// Cache boyutunu kontrol et
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int size = 0;
      
      for (final key in keys) {
        if (key.startsWith(_messagesKey)) {
          final value = prefs.getString(key);
          if (value != null) {
            size += value.length;
          }
        }
      }
      
      return size;
    } catch (e) {
      return 0;
    }
  }
}



