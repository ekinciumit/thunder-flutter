import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import '../../domain/entities/event_entity.dart';
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
import '../../domain/usecases/remove_participant_usecase.dart';
import '../../domain/usecases/cancel_event_usecase.dart';

/// EventViewModel - Clean Architecture Implementation
/// 
/// Presentation Layer - State Management
/// Bu ViewModel Clean Architecture'ın presentation katmanında yer alır.
class EventViewModel extends ChangeNotifier {
  List<EventEntity> events = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool canLoadMore = true;
  String? error;
  StreamSubscription<List<EventEntity>>? _eventsSub;
  bool _isListening = false;

  // ==================== FİLTRE STATE'LERİ ====================
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  DateTime? _startDate;
  DateTime? _endDate;
  double _selectedDistance = 10.0;
  bool _isDistanceFilterEnabled = false;
  double? _userLatitude;
  double? _userLongitude;
  List<String> _followingIds = [];
  
  // Memoization için cache
  List<EventEntity>? _cachedFilteredEvents;
  String? _lastFilterKey;

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  double get selectedDistance => _selectedDistance;
  bool get isDistanceFilterEnabled => _isDistanceFilterEnabled;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;

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
  late final RemoveParticipantUseCase _removeParticipantUseCase;
  late final CancelEventUseCase _cancelEventUseCase;

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
    _removeParticipantUseCase = RemoveParticipantUseCase(_eventRepository);
    _cancelEventUseCase = CancelEventUseCase(_eventRepository);
  }

  void listenEvents() {
    if (_isListening) return;
    _eventsSub = _getEventsUseCase().listen((eventList) {
      events = eventList;
      // Eğer ilk sayfa limit kadar geldiyse devamı olabilir
      canLoadMore = eventList.length >= 50;
      _invalidateCache(); // Events değişti, cache'i temizle
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      notifyListeners();
    });
    _isListening = true;
  }

  /// Kullanıcının etkinliklerini stream olarak getir
  Stream<List<EventEntity>> getUserEventsStream(String userId) {
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

  Future<void> addEvent(EventEntity event) async {
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

  Future<void> joinEvent(EventEntity event, String userId) async {
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

  Future<void> sendJoinRequest(EventEntity event, String userId) async {
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

  Future<void> leaveEvent(EventEntity event, String userId) async {
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

  Future<void> updateEvent(EventEntity event) async {
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

  Future<void> approveJoinRequest(EventEntity event, String userId) async {
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

  Future<void> rejectJoinRequest(EventEntity event, String userId) async {
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

  Future<void> cancelJoinRequest(EventEntity event, String userId) async {
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

  /// Katılımcıyı çıkar (sadece event sahibi)
  Future<void> removeParticipant(EventEntity event, String userId) async {
    try {
      final result = await _removeParticipantUseCase(event.id, userId);
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

  /// Event'i iptal et (sadece event sahibi)
  Future<void> cancelEvent(String eventId, String cancellationReason) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _cancelEventUseCase(eventId, cancellationReason);
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

  // ==================== FİLTRE METODLARI ====================
  
  /// Arama sorgusunu güncelle
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Kategori filtresini güncelle
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Tarih aralığını güncelle
  void setDateRange({DateTime? start, DateTime? end}) {
    if (_startDate != start || _endDate != end) {
      _startDate = start;
      _endDate = end;
      _invalidateCache();
      notifyListeners();
    }
  }

  /// Mesafe filtresini güncelle
  void setDistanceFilter({
    required bool enabled,
    double? distance,
    double? latitude,
    double? longitude,
  }) {
    _isDistanceFilterEnabled = enabled;
    if (distance != null) _selectedDistance = distance;
    if (latitude != null) _userLatitude = latitude;
    if (longitude != null) _userLongitude = longitude;
    _invalidateCache();
    notifyListeners();
  }

  /// Kullanıcı konumunu ayarla
  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _invalidateCache();
    notifyListeners();
  }

  /// Takip edilen kullanıcı ID'lerini ayarla
  void setFollowingIds(List<String> ids) {
    _followingIds = ids;
    _invalidateCache();
    notifyListeners();
  }

  /// Tüm filtreleri sıfırla
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'Tümü';
    _startDate = null;
    _endDate = null;
    _selectedDistance = 10.0;
    _isDistanceFilterEnabled = false;
    _invalidateCache();
    notifyListeners();
  }

  /// Konum filtresini sıfırla
  void resetLocationFilter() {
    _isDistanceFilterEnabled = false;
    _userLatitude = null;
    _userLongitude = null;
    _invalidateCache();
    notifyListeners();
  }

  /// Cache'i geçersiz kıl
  void _invalidateCache() {
    _cachedFilteredEvents = null;
    _lastFilterKey = null;
  }

  /// Filtre key'i oluştur (memoization için)
  String _getFilterKey() {
    return '$_searchQuery|$_selectedCategory|$_startDate|$_endDate|$_selectedDistance|$_isDistanceFilterEnabled|$_userLatitude|$_userLongitude|${_followingIds.join(',')}|${events.length}';
  }

  /// Filtrelenmiş etkinlikleri getir (memoization ile)
  List<EventEntity> getFilteredEvents() {
    final currentKey = _getFilterKey();
    
    // Cache geçerliyse döndür
    if (_cachedFilteredEvents != null && _lastFilterKey == currentKey) {
      return _cachedFilteredEvents!;
    }

    // Filtreleme
    final filteredEvents = events.where((event) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.address.toLowerCase().contains(query);
      
      final matchesCategory = _selectedCategory == 'Tümü' || 
          event.category == _selectedCategory;
      
      final matchesDate = (_startDate == null || 
          event.datetime.isAfter(_startDate!.subtract(const Duration(days: 1)))) &&
          (_endDate == null || 
          event.datetime.isBefore(_endDate!.add(const Duration(days: 1))));
      
      bool matchesDistance = true;
      if (_isDistanceFilterEnabled &&
          _userLatitude != null &&
          _userLongitude != null &&
          event.location.latitude != 0 &&
          event.location.longitude != 0) {
        final distance = _calculateDistance(
          _userLatitude!,
          _userLongitude!,
          event.location.latitude,
          event.location.longitude,
        );
        matchesDistance = distance <= _selectedDistance;
      }
      
      return matchesSearch && matchesCategory && matchesDate && matchesDistance;
    }).toList();

    // Sıralama
    filteredEvents.sort((a, b) {
      final aIsFollowing = _followingIds.contains(a.createdBy);
      final bIsFollowing = _followingIds.contains(b.createdBy);
      
      // Takip edilenlerin etkinlikleri önce gelsin
      if (aIsFollowing && !bIsFollowing) return -1;
      if (!aIsFollowing && bIsFollowing) return 1;

      // Mesafeye göre sıralama (sadece konum filtresi aktifse)
      if (_isDistanceFilterEnabled && _userLatitude != null && _userLongitude != null) {
        final da = _calculateDistance(
          _userLatitude!, _userLongitude!, 
          a.location.latitude, a.location.longitude
        );
        final db = _calculateDistance(
          _userLatitude!, _userLongitude!, 
          b.location.latitude, b.location.longitude
        );
        return da.compareTo(db);
      }
      
      // Tarihe göre sıralama (yakın tarihli etkinlikler önce)
      return a.datetime.compareTo(b.datetime);
    });

    // Cache'e kaydet
    _cachedFilteredEvents = filteredEvents;
    _lastFilterKey = currentKey;

    return filteredEvents;
  }

  /// İki koordinat arasındaki mesafeyi hesapla (km)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Dünya'nın yarıçapı km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = 0.5 - cos(dLat) / 2 + 
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * (1 - cos(dLon)) / 2;
    return R * 2 * asin(sqrt(a));
  }

  /// Belirli bir etkinlik için mesafe hesapla
  double? getDistanceForEvent(EventEntity event) {
    if (_userLatitude == null || _userLongitude == null ||
        event.location.latitude == 0 || event.location.longitude == 0) {
      return null;
    }
    return _calculateDistance(
      _userLatitude!,
      _userLongitude!,
      event.location.latitude,
      event.location.longitude,
    );
  }

  /// Event cover fotoğrafını yükle ve URL'ini döndür
  Future<String?> uploadEventCoverPhoto(String photoFilePath, {String? eventId}) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _eventRepository.uploadEventCoverPhoto(photoFilePath, eventId: eventId);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Event fotoğrafını yükle ve URL'ini döndür
  Future<String?> uploadEventPhoto(String photoFilePath, String eventId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _eventRepository.uploadEventPhoto(photoFilePath, eventId);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Tek bir event'i stream olarak getir
  Stream<EventEntity?> getEventStream(String eventId) {
    return _eventRepository.getEventStream(eventId);
  }

  /// Event comments stream
  Stream<List<Map<String, dynamic>>> getEventCommentsStream(String eventId) {
    return _eventRepository.getEventCommentsStream(eventId);
  }

  /// Event comment ekle
  Future<void> addEventComment(String eventId, String text, String userId, String userName) async {
    final result = await _eventRepository.addEventComment(eventId, text, userId, userName);
    result.fold(
      (failure) {
        error = failure.message;
        notifyListeners();
        throw Exception(failure.message);
      },
      (_) {
        // Başarılı
      },
    );
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }
}

