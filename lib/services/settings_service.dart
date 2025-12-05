import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings Service
/// 
/// Kullanıcı bildirim tercihlerini yönetir.
class SettingsService extends ChangeNotifier {
  static const String _pushEnabledKey = 'push_enabled';
  static const String _emailEnabledKey = 'email_enabled';
  static const String _eventRemindersKey = 'event_reminders';
  static const String _newFollowersKey = 'new_followers';
  static const String _messagesKey = 'messages_notifications';
  
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _eventReminders = true;
  bool _newFollowers = true;
  bool _messages = true;
  
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;
  bool get eventReminders => _eventReminders;
  bool get newFollowers => _newFollowers;
  bool get messages => _messages;
  
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pushEnabled = prefs.getBool(_pushEnabledKey) ?? true;
      _emailEnabled = prefs.getBool(_emailEnabledKey) ?? true;
      _eventReminders = prefs.getBool(_eventRemindersKey) ?? true;
      _newFollowers = prefs.getBool(_newFollowersKey) ?? true;
      _messages = prefs.getBool(_messagesKey) ?? true;
      notifyListeners();
    } catch (e) {
      // Varsayılan değerler kullanılır
    }
  }
  
  Future<void> setPushEnabled(bool value) async {
    _pushEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, value);
  }
  
  Future<void> setEmailEnabled(bool value) async {
    _emailEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailEnabledKey, value);
  }
  
  Future<void> setEventReminders(bool value) async {
    _eventReminders = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eventRemindersKey, value);
  }
  
  Future<void> setNewFollowers(bool value) async {
    _newFollowers = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_newFollowersKey, value);
  }
  
  Future<void> setMessages(bool value) async {
    _messages = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_messagesKey, value);
  }
}

