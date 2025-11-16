import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

abstract class IEventService {
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

class EventService implements IEventService {
  final _eventsRef = FirebaseFirestore.instance.collection('events');

  @override
  Future<void> addEvent(EventModel event) async {
    await _eventsRef.add(event.toMap());
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    // Include both past and upcoming, ordered by datetime, limited for performance.
    final query = _eventsRef.orderBy('datetime').limit(50);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Stream<List<EventModel>> getUserEventsStream(String userId) {
    // Kullanıcının oluşturduğu etkinlikleri getir
    final query = _eventsRef
        .where('createdBy', isEqualTo: userId)
        .orderBy('datetime', descending: true);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
  }

  @override
  Future<List<EventModel>> fetchNextEvents({DateTime? startAfter, int limit = 50}) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('events')
        .orderBy('datetime')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    await _eventsRef.doc(event.id).update(event.toMap());
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }

  @override
  Future<void> joinEvent(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
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
      // Debug: Hata durumunda log
      print('leaveEvent error: $e');
      rethrow;
    }
  }

  /// Katılma isteği gönderir (kullanıcıyı pendingRequests'e ekler)
  @override
  Future<void> sendJoinRequest(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'pendingRequests': FieldValue.arrayUnion([userId])
    });
  }

  /// Katılma isteğini onaylar (pendingRequests'ten çıkarır, approvedParticipants'e ekler)
  @override
  Future<void> approveJoinRequest(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'pendingRequests': FieldValue.arrayRemove([userId]),
      'approvedParticipants': FieldValue.arrayUnion([userId])
    });
    
    // Sistem mesajı oluştur: "Kullanıcı adı etkinliğe katıldı"
    await _addSystemMessage(eventId, userId, 'joined');
  }

  /// Sistem mesajı ekler (katılma/ayrılma bildirimleri için)
  Future<void> _addSystemMessage(String eventId, String userId, String type) async {
    try {
      // Kullanıcı bilgilerini al
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
      final docRef = await _eventsRef
          .doc(eventId)
          .collection('comments')
          .add({
        'text': messageText,
        'userId': 'system',
        'userName': 'Sistem',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('System message added successfully: ${docRef.id} - $messageText');
    } catch (e) {
      // Hata durumunda sessizce devam et
      print('System message error: $e');
      rethrow; // Hata durumunda hatayı fırlat ki görebilelim
    }
  }

  /// Katılma isteğini reddeder (pendingRequests'ten çıkarır)
  @override
  Future<void> rejectJoinRequest(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'pendingRequests': FieldValue.arrayRemove([userId])
    });
  }

  /// Katılma isteğini geri alır (kullanıcı kendi isteğini iptal eder)
  @override
  Future<void> cancelJoinRequest(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'pendingRequests': FieldValue.arrayRemove([userId])
    });
  }
} 