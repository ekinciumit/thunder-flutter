import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../../models/event_model.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/add_event_usecase.dart';
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/update_event_usecase.dart';
import '../../domain/usecases/delete_event_usecase.dart';
import '../../domain/usecases/join_event_usecase.dart';
import '../../domain/usecases/leave_event_usecase.dart';
import '../../domain/usecases/send_join_request_usecase.dart';
import '../../domain/usecases/approve_join_request_usecase.dart';
import '../../domain/usecases/reject_join_request_usecase.dart';
import '../../domain/usecases/cancel_join_request_usecase.dart';
import '../../domain/usecases/fetch_next_events_usecase.dart';

/// EventViewModel - Clean Architecture Implementation
/// 
/// Presentation Layer - State Management
/// Bu ViewModel Clean Architecture'ın presentation katmanında yer alır.
class EventViewModel extends ChangeNotifier {
  List<EventModel> events = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool canLoadMore = true;
  String? error;
  StreamSubscription<List<EventModel>>? _eventsSub;
  bool _isListening = false;

  final EventRepository _eventRepository;
  
  // Use Cases - Clean Architecture Domain Layer
  late final AddEventUseCase _addEventUseCase;
  late final GetEventsUseCase _getEventsUseCase;
  late final UpdateEventUseCase _updateEventUseCase;
  late final DeleteEventUseCase _deleteEventUseCase;
  late final JoinEventUseCase _joinEventUseCase;
  late final LeaveEventUseCase _leaveEventUseCase;
  late final SendJoinRequestUseCase _sendJoinRequestUseCase;
  late final ApproveJoinRequestUseCase _approveJoinRequestUseCase;
  late final RejectJoinRequestUseCase _rejectJoinRequestUseCase;
  late final CancelJoinRequestUseCase _cancelJoinRequestUseCase;
  late final FetchNextEventsUseCase _fetchNextEventsUseCase;

  EventViewModel({
    required EventRepository eventRepository,
    bool autoListenEvents = true,
  }) : _eventRepository = eventRepository {
    _initializeUseCases();
    // Uygulama açıldığında kullanıcı zaten giriş yaptıysa başlat
    if (autoListenEvents) {
      try {
        if (FirebaseAuth.instance.currentUser != null) {
          listenEvents();
        }
      } catch (e) {
        // Test ortamında Firebase initialize edilmemiş olabilir
        // Bu durumda sessizce devam et
      }
    }
  }
  
  /// Use Cases'i oluştur
  void _initializeUseCases() {
    _addEventUseCase = AddEventUseCase(_eventRepository);
    _getEventsUseCase = GetEventsUseCase(_eventRepository);
    _updateEventUseCase = UpdateEventUseCase(_eventRepository);
    _deleteEventUseCase = DeleteEventUseCase(_eventRepository);
    _joinEventUseCase = JoinEventUseCase(_eventRepository);
    _leaveEventUseCase = LeaveEventUseCase(_eventRepository);
    _sendJoinRequestUseCase = SendJoinRequestUseCase(_eventRepository);
    _approveJoinRequestUseCase = ApproveJoinRequestUseCase(_eventRepository);
    _rejectJoinRequestUseCase = RejectJoinRequestUseCase(_eventRepository);
    _cancelJoinRequestUseCase = CancelJoinRequestUseCase(_eventRepository);
    _fetchNextEventsUseCase = FetchNextEventsUseCase(_eventRepository);
  }

  void listenEvents() {
    if (_isListening) return;
    _eventsSub = _getEventsUseCase().listen((eventList) {
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

  /// Kullanıcının etkinliklerini stream olarak getir
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    return _eventRepository.getUserEventsStream(userId);
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !canLoadMore || events.isEmpty) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final lastDate = events.last.datetime;
      final result = await _fetchNextEventsUseCase(startAfter: lastDate, limit: 50);
      
      result.fold(
        (failure) {
          error = failure.message;
        },
        (next) {
          if (next.isEmpty) {
            canLoadMore = false;
          } else {
            // Yinelenenleri önlemek için id bazlı filtre
            final existingIds = events.map((e) => e.id).toSet();
            final toAdd = next.where((e) => !existingIds.contains(e.id)).toList();
            events.addAll(toAdd);
          }
        },
      );
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
      final result = await _addEventUseCase(event);
      result.fold(
        (failure) {
          error = failure.message;
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> joinEvent(EventModel event, String userId) async {
    try {
      final result = await _joinEventUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendJoinRequest(EventModel event, String userId) async {
    try {
      final result = await _sendJoinRequestUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveEvent(EventModel event, String userId) async {
    try {
      final result = await _leaveEventUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
          notifyListeners();
        },
      );
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
      final result = await _updateEventUseCase(event);
      result.fold(
        (failure) {
          error = failure.message;
        },
        (_) {
          // Başarılı
        },
      );
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
      final result = await _deleteEventUseCase(eventId);
      result.fold(
        (failure) {
          error = failure.message;
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> approveJoinRequest(EventModel event, String userId) async {
    try {
      final result = await _approveJoinRequestUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectJoinRequest(EventModel event, String userId) async {
    try {
      final result = await _rejectJoinRequestUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelJoinRequest(EventModel event, String userId) async {
    try {
      final result = await _cancelJoinRequestUseCase(event.id, userId);
      result.fold(
        (failure) {
          error = failure.message;
          notifyListeners();
        },
        (_) {
          // Başarılı
          notifyListeners();
        },
      );
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

