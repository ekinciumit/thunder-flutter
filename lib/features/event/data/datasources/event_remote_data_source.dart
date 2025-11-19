import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../models/event_model.dart';
import '../../../../core/errors/exceptions.dart';

/// Event Remote Data Source Interface
/// 
/// Clean Architecture Data Layer
/// Firebase işlemleri için abstract interface.
abstract class EventRemoteDataSource {
  Future<void> addEvent(EventModel event);
  Stream<List<EventModel>> getEventsStream();
  Stream<List<EventModel>> getUserEventsStream(String userId);
  Future<List<EventModel>> fetchNextEvents({DateTime? startAfter, int limit});
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
  Future<void> sendJoinRequest(String eventId, String userId);
  Future<void> approveJoinRequest(String eventId, String userId);
  Future<void> rejectJoinRequest(String eventId, String userId);
  Future<void> cancelJoinRequest(String eventId, String userId);
}

/// Event Remote Data Source Implementation
/// 
/// Clean Architecture Data Layer
/// Firebase Firestore işlemlerini yapar.
class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _eventsRef;

  EventRemoteDataSourceImpl() : _eventsRef = FirebaseFirestore.instance.collection('events');

  @override
  Future<void> addEvent(EventModel event) async {
    try {
      await _eventsRef.add(event.toMap());
    } catch (e) {
      throw ServerException('Etkinlik eklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    try {
      final query = _eventsRef.orderBy('datetime').limit(50);
      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      throw ServerException('Etkinlikler getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    try {
      final query = _eventsRef
          .where('createdBy', isEqualTo: userId)
          .orderBy('datetime', descending: true);
      return query.snapshots().map((snapshot) =>
          snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
    } catch (e) {
      throw ServerException('Kullanıcı etkinlikleri getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<List<EventModel>> fetchNextEvents({DateTime? startAfter, int limit = 50}) async {
    try {
      Query<Map<String, dynamic>> query = _eventsRef
          .orderBy('datetime')
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw ServerException('Etkinlikler getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    try {
      await _eventsRef.doc(event.id).update(event.toMap());
    } catch (e) {
      throw ServerException('Etkinlik güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsRef.doc(eventId).delete();
    } catch (e) {
      throw ServerException('Etkinlik silinirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw ServerException('Etkinliğe katılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      // ÖNCE sistem mesajını oluştur (kullanıcı hala katılımcıyken)
      await _addSystemMessage(eventId, userId, 'left');
      
      // SONRA kullanıcıyı array'lerden çıkar
      await _eventsRef.doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'approvedParticipants': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw ServerException('Etkinlikten ayrılırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> sendJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği gönderilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> approveJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
        'approvedParticipants': FieldValue.arrayUnion([userId])
      });
      
      // Sistem mesajı oluştur
      await _addSystemMessage(eventId, userId, 'joined');
    } catch (e) {
      throw ServerException('Katılma isteği onaylanırken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği reddedilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> cancelJoinRequest(String eventId, String userId) async {
    try {
      await _eventsRef.doc(eventId).update({
        'pendingRequests': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      throw ServerException('Katılma isteği iptal edilirken hata oluştu: ${e.toString()}');
    }
  }

  /// Sistem mesajı ekler (katılma/ayrılma bildirimleri için)
  Future<void> _addSystemMessage(String eventId, String userId, String type) async {
    try {
      // Kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.exists 
          ? (userDoc.data()?['displayName'] ?? 'Bir kullanıcı')
          : 'Bir kullanıcı';
      
      String messageText;
      if (type == 'joined') {
        messageText = '$userName etkinliğe katıldı';
      } else if (type == 'left') {
        messageText = '$userName etkinlikten ayrıldı';
      } else {
        return;
      }
      
      // Sistem mesajını comments collection'ına ekle
      await _eventsRef
          .doc(eventId)
          .collection('comments')
          .add({
        'text': messageText,
        'userId': 'system',
        'userName': 'Sistem',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Sistem mesajı hatası kritik değil, sessizce devam et
      // Sadece log'a yaz
      if (kDebugMode) {
        debugPrint('⚠️ Sistem mesajı eklenemedi: $e');
      }
    }
  }
}

