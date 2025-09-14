import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

abstract class IEventService {
  Future<void> addEvent(EventModel event);
  Stream<List<EventModel>> getEventsStream();
  Future<void> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
  Future<void> sendJoinRequest(String eventId, String userId);
  Future<void> approveJoinRequest(String eventId, String userId);
  Future<void> rejectJoinRequest(String eventId, String userId);
}

class EventService implements IEventService {
  final _eventsRef = FirebaseFirestore.instance.collection('events');

  @override
  Future<void> addEvent(EventModel event) async {
    await _eventsRef.add(event.toMap());
  }

  @override
  Stream<List<EventModel>> getEventsStream() {
    return _eventsRef.orderBy('datetime').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList()
    );
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
    await _eventsRef.doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
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
  }

  /// Katılma isteğini reddeder (pendingRequests'ten çıkarır)
  @override
  Future<void> rejectJoinRequest(String eventId, String userId) async {
    await _eventsRef.doc(eventId).update({
      'pendingRequests': FieldValue.arrayRemove([userId])
    });
  }
} 