import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/models/event_model.dart';

void main() {
  group('EventModel', () {
    final testLocation = const GeoPoint(41.0082, 28.9784);
    final testDatetime = DateTime.now().add(const Duration(days: 1));

    test('should create EventModel with all fields', () {
      // Arrange & Act
      final event = EventModel(
        id: 'event-123',
        title: 'Test Event',
        description: 'Test Description',
        location: testLocation,
        address: 'Test Address',
        datetime: testDatetime,
        quota: 10,
        createdBy: 'user-123',
        participants: ['user-1', 'user-2'],
        coverPhotoUrl: 'https://example.com/photo.jpg',
        category: 'Spor',
        pendingRequests: ['user-3'],
        approvedParticipants: ['user-1'],
      );

      // Assert
      expect(event.id, 'event-123');
      expect(event.title, 'Test Event');
      expect(event.description, 'Test Description');
      expect(event.location, testLocation);
      expect(event.address, 'Test Address');
      expect(event.datetime, testDatetime);
      expect(event.quota, 10);
      expect(event.createdBy, 'user-123');
      expect(event.participants, ['user-1', 'user-2']);
      expect(event.coverPhotoUrl, 'https://example.com/photo.jpg');
      expect(event.category, 'Spor');
      expect(event.pendingRequests, ['user-3']);
      expect(event.approvedParticipants, ['user-1']);
    });

    test('should create EventModel with default category', () {
      // Arrange & Act
      final event = EventModel(
        id: 'event-123',
        title: 'Test Event',
        description: 'Test Description',
        location: testLocation,
        address: 'Test Address',
        datetime: testDatetime,
        quota: 10,
        createdBy: 'user-123',
        participants: [],
      );

      // Assert
      expect(event.category, 'Diğer');
      expect(event.pendingRequests, isEmpty);
      expect(event.approvedParticipants, isEmpty);
    });

    group('fromMap', () {
      test('should create EventModel from map with all fields', () {
        // Arrange
        const id = 'event-123';
        final map = {
          'title': 'Test Event',
          'description': 'Test Description',
          'location': testLocation,
          'address': 'Test Address',
          'datetime': Timestamp.fromDate(testDatetime),
          'quota': 10,
          'createdBy': 'user-123',
          'participants': ['user-1', 'user-2'],
          'coverPhotoUrl': 'https://example.com/photo.jpg',
          'category': 'Spor',
          'pendingRequests': ['user-3'],
          'approvedParticipants': ['user-1'],
        };

        // Act
        final event = EventModel.fromMap(map, id);

        // Assert
        expect(event.id, id);
        expect(event.title, map['title']);
        expect(event.description, map['description']);
        expect(event.location, map['location']);
        expect(event.address, map['address']);
        expect(event.datetime, testDatetime);
        expect(event.quota, map['quota']);
        expect(event.createdBy, map['createdBy']);
        expect(event.participants, map['participants']);
        expect(event.coverPhotoUrl, map['coverPhotoUrl']);
        expect(event.category, map['category']);
        expect(event.pendingRequests, map['pendingRequests']);
        expect(event.approvedParticipants, map['approvedParticipants']);
      });

      test('should create EventModel from map with minimal fields', () {
        // Arrange
        const id = 'event-123';
        final map = {
          'title': 'Test Event',
          'description': 'Test Description',
          'location': testLocation,
          'address': 'Test Address',
          'datetime': Timestamp.fromDate(testDatetime),
          'quota': 10,
          'createdBy': 'user-123',
          'participants': [],
        };

        // Act
        final event = EventModel.fromMap(map, id);

        // Assert
        expect(event.id, id);
        expect(event.title, map['title']);
        expect(event.category, 'Diğer');
        expect(event.pendingRequests, isEmpty);
        expect(event.approvedParticipants, isEmpty);
      });

      test('should handle missing optional fields', () {
        // Arrange
        const id = 'event-123';
        final map = {
          'title': 'Test Event',
          'description': 'Test Description',
          'location': testLocation,
          'address': 'Test Address',
          'datetime': Timestamp.fromDate(testDatetime),
          'quota': 10,
          'createdBy': 'user-123',
          'participants': [],
          'coverPhotoUrl': null,
        };

        // Act
        final event = EventModel.fromMap(map, id);

        // Assert
        expect(event.coverPhotoUrl, isNull);
      });

      test('should handle empty title with default', () {
        // Arrange
        const id = 'event-123';
        final map = {
          'title': null,
          'description': 'Test Description',
          'location': testLocation,
          'address': 'Test Address',
          'datetime': Timestamp.fromDate(testDatetime),
          'quota': 10,
          'createdBy': 'user-123',
          'participants': [],
        };

        // Act
        final event = EventModel.fromMap(map, id);

        // Assert
        expect(event.title, '');
      });
    });

    group('toMap', () {
      test('should convert EventModel to map with all fields', () {
        // Arrange
        final event = EventModel(
          id: 'event-123',
          title: 'Test Event',
          description: 'Test Description',
          location: testLocation,
          address: 'Test Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: ['user-1', 'user-2'],
          coverPhotoUrl: 'https://example.com/photo.jpg',
          category: 'Spor',
          pendingRequests: ['user-3'],
          approvedParticipants: ['user-1'],
        );

        // Act
        final map = event.toMap();

        // Assert
        expect(map['title'], event.title);
        expect(map['description'], event.description);
        expect(map['location'], event.location);
        expect(map['address'], event.address);
        expect((map['datetime'] as Timestamp).toDate(), event.datetime);
        expect(map['quota'], event.quota);
        expect(map['createdBy'], event.createdBy);
        expect(map['participants'], event.participants);
        expect(map['coverPhotoUrl'], event.coverPhotoUrl);
        expect(map['category'], event.category);
        expect(map['pendingRequests'], event.pendingRequests);
        expect(map['approvedParticipants'], event.approvedParticipants);
      });

      test('should convert EventModel to map with minimal fields', () {
        // Arrange
        final event = EventModel(
          id: 'event-123',
          title: 'Test Event',
          description: 'Test Description',
          location: testLocation,
          address: 'Test Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: [],
        );

        // Act
        final map = event.toMap();

        // Assert
        expect(map['title'], event.title);
        expect(map['coverPhotoUrl'], isNull);
        expect(map['category'], 'Diğer');
      });

      test('should round-trip correctly (fromMap -> toMap -> fromMap)', () {
        // Arrange
        const id = 'event-123';
        final originalMap = {
          'title': 'Test Event',
          'description': 'Test Description',
          'location': testLocation,
          'address': 'Test Address',
          'datetime': Timestamp.fromDate(testDatetime),
          'quota': 10,
          'createdBy': 'user-123',
          'participants': ['user-1', 'user-2'],
          'coverPhotoUrl': 'https://example.com/photo.jpg',
          'category': 'Spor',
          'pendingRequests': ['user-3'],
          'approvedParticipants': ['user-1'],
        };

        // Act
        final event = EventModel.fromMap(originalMap, id);
        final map = event.toMap();
        final roundTripEvent = EventModel.fromMap(map, id);

        // Assert
        expect(roundTripEvent.id, id);
        expect(roundTripEvent.title, event.title);
        expect(roundTripEvent.description, event.description);
        expect(roundTripEvent.location.latitude, event.location.latitude);
        expect(roundTripEvent.location.longitude, event.location.longitude);
        expect(roundTripEvent.address, event.address);
        expect(roundTripEvent.datetime, event.datetime);
        expect(roundTripEvent.quota, event.quota);
        expect(roundTripEvent.createdBy, event.createdBy);
        expect(roundTripEvent.participants, event.participants);
        expect(roundTripEvent.coverPhotoUrl, event.coverPhotoUrl);
        expect(roundTripEvent.category, event.category);
        expect(roundTripEvent.pendingRequests, event.pendingRequests);
        expect(roundTripEvent.approvedParticipants, event.approvedParticipants);
      });
    });

    group('copyWith', () {
      test('should copy EventModel with updated fields', () {
        // Arrange
        final original = EventModel(
          id: 'event-123',
          title: 'Original Title',
          description: 'Original Description',
          location: testLocation,
          address: 'Original Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: ['user-1'],
        );

        // Act
        final copied = original.copyWith(
          title: 'New Title',
          description: 'New Description',
          quota: 20,
        );

        // Assert
        expect(copied.id, original.id);
        expect(copied.title, 'New Title');
        expect(copied.description, 'New Description');
        expect(copied.quota, 20);
        expect(copied.location, original.location);
        expect(copied.address, original.address);
        expect(copied.datetime, original.datetime);
        expect(copied.createdBy, original.createdBy);
        expect(copied.participants, original.participants);
      });

      test('should copy EventModel without changes when no parameters', () {
        // Arrange
        final original = EventModel(
          id: 'event-123',
          title: 'Test Event',
          description: 'Test Description',
          location: testLocation,
          address: 'Test Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: ['user-1'],
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.id, original.id);
        expect(copied.title, original.title);
        expect(copied.description, original.description);
        expect(copied.quota, original.quota);
        expect(copied.participants, original.participants);
      });

      test('should update all fields with copyWith', () {
        // Arrange
        final original = EventModel(
          id: 'event-123',
          title: 'Old Title',
          description: 'Old Description',
          location: testLocation,
          address: 'Old Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: ['old1'],
        );

        final newLocation = const GeoPoint(40.0, 30.0);
        final newDatetime = DateTime.now().add(const Duration(days: 2));

        // Act
        final copied = original.copyWith(
          id: 'event-456',
          title: 'New Title',
          description: 'New Description',
          location: newLocation,
          address: 'New Address',
          datetime: newDatetime,
          quota: 20,
          createdBy: 'user-456',
          participants: ['new1', 'new2'],
          coverPhotoUrl: 'https://new.com/photo.jpg',
          category: 'Spor',
          pendingRequests: ['new3'],
          approvedParticipants: ['new1'],
        );

        // Assert
        expect(copied.id, 'event-456');
        expect(copied.title, 'New Title');
        expect(copied.description, 'New Description');
        expect(copied.location, newLocation);
        expect(copied.address, 'New Address');
        expect(copied.datetime, newDatetime);
        expect(copied.quota, 20);
        expect(copied.createdBy, 'user-456');
        expect(copied.participants, ['new1', 'new2']);
        expect(copied.coverPhotoUrl, 'https://new.com/photo.jpg');
        expect(copied.category, 'Spor');
        expect(copied.pendingRequests, ['new3']);
        expect(copied.approvedParticipants, ['new1']);
      });

      test('should preserve original value when null is passed to copyWith', () {
        // Arrange
        final original = EventModel(
          id: 'event-123',
          title: 'Test Event',
          description: 'Test Description',
          location: testLocation,
          address: 'Test Address',
          datetime: testDatetime,
          quota: 10,
          createdBy: 'user-123',
          participants: [],
          coverPhotoUrl: 'https://old.com/photo.jpg',
        );

        // Act
        final copied = original.copyWith(
          coverPhotoUrl: null,
        );

        // Assert - copyWith preserves original value when null is passed
        // This is standard Dart copyWith behavior (null means "don't change")
        expect(copied.coverPhotoUrl, original.coverPhotoUrl);
      });
    });
  });
}

