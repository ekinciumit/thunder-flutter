import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/data/datasources/event_remote_data_source.dart';
import 'package:thunder/models/event_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late EventRemoteDataSourceImpl dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = EventRemoteDataSourceImpl(firestore: fakeFirestore);
  });

  group('EventRemoteDataSourceImpl', () {
    final testEvent = EventModel(
      id: 'event-123',
      title: 'Test Event',
      description: 'Test Description',
      location: const GeoPoint(41.0082, 28.9784),
      address: 'Test Address',
      datetime: DateTime.now().add(const Duration(days: 1)),
      quota: 10,
      createdBy: 'user-123',
      participants: [],
    );

    group('addEvent', () {
      test('should add event successfully', () async {
        // Act
        await dataSource.addEvent(testEvent);

        // Assert
        // Event is added with .add(), so we need to check if it exists in the collection
        final snapshot = await fakeFirestore.collection('events').get();
        expect(snapshot.docs, isNotEmpty);
      });

      test('should add event with all required fields', () async {
        // Arrange
        final eventWithAllFields = EventModel(
          id: 'event-full',
          title: 'Full Event',
          description: 'Full Description',
          location: const GeoPoint(41.0082, 28.9784),
          address: 'Full Address',
          datetime: DateTime.now(),
          quota: 20,
          createdBy: 'user-full',
          participants: ['user1', 'user2'],
          coverPhotoUrl: 'https://example.com/photo.jpg',
          category: 'Spor',
        );

        // Act
        await dataSource.addEvent(eventWithAllFields);

        // Assert
        final snapshot = await fakeFirestore.collection('events').get();
        expect(snapshot.docs.length, greaterThanOrEqualTo(1));
      });
    });

    group('getEventsStream', () {
      test('should return empty stream when no events exist', () async {
        // Act
        final stream = dataSource.getEventsStream();

        // Assert
        final events = await stream.first;
        expect(events, isEmpty);
      });

      test('should return events stream', () async {
        // Arrange
        final eventData = testEvent.toMap();
        await fakeFirestore.collection('events').add(eventData);

        // Act
        final stream = dataSource.getEventsStream();

        // Assert
        final events = await stream.first;
        expect(events, isNotEmpty);
      });

      test('should return events ordered by datetime', () async {
        // Arrange
        final event1 = testEvent.copyWith(
          id: 'event-1',
          datetime: DateTime.now().add(const Duration(days: 1)),
        );
        final event2 = testEvent.copyWith(
          id: 'event-2',
          datetime: DateTime.now().add(const Duration(days: 2)),
        );

        await fakeFirestore.collection('events').add(event2.toMap());
        await fakeFirestore.collection('events').add(event1.toMap());

        // Act
        final stream = dataSource.getEventsStream();

        // Assert
        final events = await stream.first;
        expect(events.length, greaterThanOrEqualTo(2));
        // Events should be ordered by datetime (ascending)
        for (int i = 0; i < events.length - 1; i++) {
          expect(
            events[i].datetime.isBefore(events[i + 1].datetime) ||
                events[i].datetime.isAtSameMomentAs(events[i + 1].datetime),
            true,
          );
        }
      });
    });

    group('getUserEventsStream', () {
      const testUserId = 'user-123';

      test('should return empty stream when user has no events', () async {
        // Act
        final stream = dataSource.getUserEventsStream(testUserId);

        // Assert
        final events = await stream.first;
        expect(events, isEmpty);
      });

      test('should return user events stream', () async {
        // Arrange
        final userEvent = testEvent.copyWith(createdBy: testUserId);
        await fakeFirestore.collection('events').add(userEvent.toMap());

        // Act
        final stream = dataSource.getUserEventsStream(testUserId);

        // Assert
        final events = await stream.first;
        expect(events, isNotEmpty);
        expect(events.first.createdBy, testUserId);
      });

      test('should only return events created by user', () async {
        // Arrange
        final userEvent = testEvent.copyWith(createdBy: testUserId);
        final otherEvent = testEvent.copyWith(
          id: 'event-other',
          createdBy: 'other-user',
        );

        await fakeFirestore.collection('events').add(userEvent.toMap());
        await fakeFirestore.collection('events').add(otherEvent.toMap());

        // Act
        final stream = dataSource.getUserEventsStream(testUserId);

        // Assert
        final events = await stream.first;
        expect(events.every((e) => e.createdBy == testUserId), true);
      });
    });

    group('fetchNextEvents', () {
      test('should return empty list when no events exist', () async {
        // Act
        final result = await dataSource.fetchNextEvents();

        // Assert
        expect(result, isEmpty);
      });

      test('should fetch events with default limit', () async {
        // Arrange
        for (int i = 0; i < 3; i++) {
          final event = testEvent.copyWith(
            id: 'event-$i',
            datetime: DateTime.now().add(Duration(days: i)),
          );
          await fakeFirestore.collection('events').add(event.toMap());
        }

        // Act
        final result = await dataSource.fetchNextEvents();

        // Assert
        expect(result.length, lessThanOrEqualTo(50));
        expect(result, isNotEmpty);
      });

      test('should respect limit parameter', () async {
        // Arrange
        for (int i = 0; i < 10; i++) {
          final event = testEvent.copyWith(
            id: 'event-$i',
            datetime: DateTime.now().add(Duration(days: i)),
          );
          await fakeFirestore.collection('events').add(event.toMap());
        }

        // Act
        final result = await dataSource.fetchNextEvents(limit: 5);

        // Assert
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('should use startAfter parameter', () async {
        // Arrange
        final startTime = DateTime.now();
        final event1 = testEvent.copyWith(
          id: 'event-1',
          datetime: startTime.add(const Duration(days: 1)),
        );
        final event2 = testEvent.copyWith(
          id: 'event-2',
          datetime: startTime.add(const Duration(days: 2)),
        );

        await fakeFirestore.collection('events').add(event1.toMap());
        await fakeFirestore.collection('events').add(event2.toMap());

        // Act
        final result = await dataSource.fetchNextEvents(
          startAfter: startTime,
          limit: 10,
        );

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('updateEvent', () {
      test('should update event successfully', () async {
        // Arrange
        await fakeFirestore.collection('events').doc(testEvent.id).set(testEvent.toMap());
        final updatedEvent = testEvent.copyWith(title: 'Updated Title');

        // Act
        await dataSource.updateEvent(updatedEvent);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEvent.id).get();
        expect(doc.data()!['title'], 'Updated Title');
      });

      test('should update multiple fields', () async {
        // Arrange
        await fakeFirestore.collection('events').doc(testEvent.id).set(testEvent.toMap());
        final updatedEvent = testEvent.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
          quota: 20,
        );

        // Act
        await dataSource.updateEvent(updatedEvent);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEvent.id).get();
        expect(doc.data()!['title'], 'Updated Title');
        expect(doc.data()!['description'], 'Updated Description');
        expect(doc.data()!['quota'], 20);
      });
    });

    group('deleteEvent', () {
      test('should delete event successfully', () async {
        // Arrange
        await fakeFirestore.collection('events').doc(testEvent.id).set(testEvent.toMap());

        // Act
        await dataSource.deleteEvent(testEvent.id);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEvent.id).get();
        expect(doc.exists, false);
      });

      test('should delete multiple events', () async {
        // Arrange
        final event1 = testEvent.copyWith(id: 'event-1');
        final event2 = testEvent.copyWith(id: 'event-2');
        
        await fakeFirestore.collection('events').doc('event-1').set(event1.toMap());
        await fakeFirestore.collection('events').doc('event-2').set(event2.toMap());

        // Act
        await dataSource.deleteEvent('event-1');
        await dataSource.deleteEvent('event-2');

        // Assert
        final doc1 = await fakeFirestore.collection('events').doc('event-1').get();
        final doc2 = await fakeFirestore.collection('events').doc('event-2').get();
        expect(doc1.exists, false);
        expect(doc2.exists, false);
      });
    });

    group('joinEvent', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        await fakeFirestore.collection('events').doc(testEventId).set(testEvent.toMap());
      });

      test('should add user to participants', () async {
        // Act
        await dataSource.joinEvent(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final participants = List<String>.from(doc.data()!['participants'] ?? []);
        expect(participants, contains(testUserId));
      });
    });

    group('leaveEvent', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        final eventWithParticipant = testEvent.copyWith(
          participants: [testUserId],
          approvedParticipants: [testUserId],
        );
        await fakeFirestore.collection('events').doc(testEventId).set(eventWithParticipant.toMap());
        await fakeFirestore.collection('users').doc(testUserId).set({
          'displayName': 'Test User',
        });
      });

      test('should remove user from participants and approvedParticipants', () async {
        // Act
        await dataSource.leaveEvent(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final participants = List<String>.from(doc.data()!['participants'] ?? []);
        final approvedParticipants = List<String>.from(doc.data()!['approvedParticipants'] ?? []);
        
        expect(participants, isNot(contains(testUserId)));
        expect(approvedParticipants, isNot(contains(testUserId)));
      });
    });

    group('sendJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        await fakeFirestore.collection('events').doc(testEventId).set(testEvent.toMap());
      });

      test('should add user to pendingRequests', () async {
        // Act
        await dataSource.sendJoinRequest(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final pendingRequests = List<String>.from(doc.data()!['pendingRequests'] ?? []);
        expect(pendingRequests, contains(testUserId));
      });
    });

    group('approveJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        final eventWithRequest = testEvent.copyWith(
          pendingRequests: [testUserId],
        );
        await fakeFirestore.collection('events').doc(testEventId).set(eventWithRequest.toMap());
        await fakeFirestore.collection('users').doc(testUserId).set({
          'displayName': 'Test User',
        });
      });

      test('should move user from pendingRequests to approvedParticipants', () async {
        // Act
        await dataSource.approveJoinRequest(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final pendingRequests = List<String>.from(doc.data()!['pendingRequests'] ?? []);
        final approvedParticipants = List<String>.from(doc.data()!['approvedParticipants'] ?? []);

        expect(pendingRequests, isNot(contains(testUserId)));
        expect(approvedParticipants, contains(testUserId));
      });
    });

    group('rejectJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        final eventWithRequest = testEvent.copyWith(
          pendingRequests: [testUserId],
        );
        await fakeFirestore.collection('events').doc(testEventId).set(eventWithRequest.toMap());
      });

      test('should remove user from pendingRequests', () async {
        // Act
        await dataSource.rejectJoinRequest(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final pendingRequests = List<String>.from(doc.data()!['pendingRequests'] ?? []);
        expect(pendingRequests, isNot(contains(testUserId)));
      });
    });

    group('cancelJoinRequest', () {
      const testEventId = 'event-123';
      const testUserId = 'user-123';

      setUp(() async {
        final eventWithRequest = testEvent.copyWith(
          pendingRequests: [testUserId],
        );
        await fakeFirestore.collection('events').doc(testEventId).set(eventWithRequest.toMap());
      });

      test('should remove user from pendingRequests', () async {
        // Act
        await dataSource.cancelJoinRequest(testEventId, testUserId);

        // Assert
        final doc = await fakeFirestore.collection('events').doc(testEventId).get();
        final pendingRequests = List<String>.from(doc.data()!['pendingRequests'] ?? []);
        expect(pendingRequests, isNot(contains(testUserId)));
      });
    });
  });
}

