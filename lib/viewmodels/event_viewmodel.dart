import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class EventViewModel extends ChangeNotifier {
  final IEventService _eventService;
  List<EventModel> events = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool canLoadMore = true;
  String? error;
  StreamSubscription<List<EventModel>>? _eventsSub;
  bool _isListening = false;

  EventViewModel({IEventService? eventService}) : _eventService = eventService ?? EventService() {
    // Uygulama açıldığında kullanıcı zaten giriş yaptıysa başlat
    if (FirebaseAuth.instance.currentUser != null) {
      listenEvents();
    }
  }

  void listenEvents() {
    if (_isListening) return;
    _eventsSub = _eventService.getEventsStream().listen((eventList) {
      events = eventList;
      // Eğer ilk sayfa limit kadar geldiyse devamı olabilir
      canLoadMore = eventList.length >= 50;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
    _isListening = true;
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !canLoadMore || events.isEmpty) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final lastDate = events.last.datetime;
      final next = await _eventService.fetchNextEvents(startAfter: lastDate, limit: 50);
      if (next.isEmpty) {
        canLoadMore = false;
      } else {
        // Yinelenenleri önlemek için id bazlı filtre
        final existingIds = events.map((e) => e.id).toSet();
        final toAdd = next.where((e) => !existingIds.contains(e.id)).toList();
        events.addAll(toAdd);
      }
    } catch (e) {
      error = e.toString();
    }
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> addEvent(EventModel event) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _eventService.addEvent(event);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> joinEvent(EventModel event, String userId) async {
    try {
      await _eventService.joinEvent(event.id, userId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendJoinRequest(EventModel event, String userId) async {
    try {
      await _eventService.sendJoinRequest(event.id, userId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveEvent(EventModel event, String userId) async {
    try {
      await _eventService.leaveEvent(event.id, userId);
      notifyListeners(); // UI'ı güncelle
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateEvent(EventModel event) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _eventService.updateEvent(event);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _eventService.deleteEvent(eventId);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> approveJoinRequest(EventModel event, String userId) async {
    try {
      await _eventService.approveJoinRequest(event.id, userId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectJoinRequest(EventModel event, String userId) async {
    try {
      await _eventService.rejectJoinRequest(event.id, userId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelJoinRequest(EventModel event, String userId) async {
    try {
      await _eventService.cancelJoinRequest(event.id, userId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }
} 