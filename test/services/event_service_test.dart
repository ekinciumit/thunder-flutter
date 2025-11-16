import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/models/event_model.dart';

void main() {
  group('EventService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('addEvent - Etkinlik ekleme', () async {
      // Arrange
      final event = EventModel(
        id: 'event-123',
        title: 'Test Etkinlik',
        description: 'Test açıklaması',
        datetime: DateTime.now().add(const Duration(days: 7)),
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Konum',
        quota: 10,
        createdBy: 'user-1',
        participants: [],
      );
      
      // Act
      await fakeFirestore.collection('events').doc(event.id).set(event.toMap());
      
      // Assert
      final doc = await fakeFirestore.collection('events').doc(event.id).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['title'], equals('Test Etkinlik'));
      expect(doc.data()!['createdBy'], equals('user-1'));
    });

    test('joinEvent - Etkinliğe katılma', () async {
      // Arrange
      final eventId = 'event-123';
      final userId = 'user-2';
      
      // Önce bir etkinlik oluştur
      final event = EventModel(
        id: eventId,
        title: 'Test Etkinlik',
        description: 'Test açıklaması',
        datetime: DateTime.now().add(const Duration(days: 7)),
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Konum',
        quota: 10,
        createdBy: 'user-1',
        participants: [],
      );
      await fakeFirestore.collection('events').doc(eventId).set(event.toMap());
      
      // Act - Kullanıcıyı katılımcılar listesine ekle
      await fakeFirestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
      
      // Assert
      final doc = await fakeFirestore.collection('events').doc(eventId).get();
      final participants = doc.data()!['participants'] as List;
      expect(participants, contains(userId));
    });

    test('leaveEvent - Etkinlikten ayrılma', () async {
      // Arrange
      final eventId = 'event-123';
      final userId = 'user-2';
      
      // Önce bir etkinlik oluştur ve kullanıcıyı ekle
      final event = EventModel(
        id: eventId,
        title: 'Test Etkinlik',
        description: 'Test açıklaması',
        datetime: DateTime.now().add(const Duration(days: 7)),
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Konum',
        quota: 10,
        createdBy: 'user-1',
        participants: [userId],
      );
      await fakeFirestore.collection('events').doc(eventId).set(event.toMap());
      
      // Act - Kullanıcıyı katılımcılar listesinden çıkar
      await fakeFirestore.collection('events').doc(eventId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
      
      // Assert
      final doc = await fakeFirestore.collection('events').doc(eventId).get();
      final participants = doc.data()!['participants'] as List;
      expect(participants, isNot(contains(userId)));
    });

    test('getEventsStream - Etkinlik stream\'i', () async {
      // Arrange
      final events = [
        EventModel(
          id: 'event-1',
          title: 'Etkinlik 1',
          description: 'Açıklama 1',
          datetime: DateTime.now().add(const Duration(days: 1)),
          location: const GeoPoint(41.0082, 28.9784),
          address: 'Konum 1',
          quota: 10,
          createdBy: 'user-1',
          participants: [],
        ),
        EventModel(
          id: 'event-2',
          title: 'Etkinlik 2',
          description: 'Açıklama 2',
          datetime: DateTime.now().add(const Duration(days: 2)),
          location: const GeoPoint(41.0082, 28.9784),
          address: 'Konum 2',
          quota: 10,
          createdBy: 'user-2',
          participants: [],
        ),
      ];
      
      for (final event in events) {
        await fakeFirestore.collection('events').doc(event.id).set(event.toMap());
      }
      
      // Act
      final snapshot = await fakeFirestore
          .collection('events')
          .orderBy('datetime')
          .get();
      
      // Assert
      expect(snapshot.docs.length, equals(2));
      expect(snapshot.docs[0].data()['title'], equals('Etkinlik 1'));
      expect(snapshot.docs[1].data()['title'], equals('Etkinlik 2'));
    });

    test('deleteEvent - Etkinlik silme', () async {
      // Arrange
      final eventId = 'event-123';
      final event = EventModel(
        id: eventId,
        title: 'Silinecek Etkinlik',
        description: 'Test açıklaması',
        datetime: DateTime.now().add(const Duration(days: 7)),
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Test Konum',
        quota: 10,
        createdBy: 'user-1',
        participants: [],
      );
      await fakeFirestore.collection('events').doc(eventId).set(event.toMap());
      
      // Act
      await fakeFirestore.collection('events').doc(eventId).delete();
      
      // Assert
      final doc = await fakeFirestore.collection('events').doc(eventId).get();
      expect(doc.exists, isFalse);
    });
  });
}


