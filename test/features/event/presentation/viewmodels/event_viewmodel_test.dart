import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/presentation/viewmodels/event_viewmodel.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/event_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'event_viewmodel_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late EventViewModel viewModel;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    viewModel = EventViewModel(
      eventRepository: mockRepository,
      autoListenEvents: false, // Test için otomatik dinlemeyi kapat
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('EventViewModel', () {
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

    test('should initialize with empty events list', () {
      // Assert
      expect(viewModel.events, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.isLoadingMore, false);
      expect(viewModel.canLoadMore, true);
      expect(viewModel.error, isNull);
    });

    group('listenEvents', () {
      test('should listen to events stream and update events', () async {
        // Arrange
        final testEvents = [testEvent];
        final streamController = StreamController<List<EventModel>>();
        when(mockRepository.getEventsStream())
            .thenAnswer((_) => streamController.stream);

        // Act
        viewModel.listenEvents();
        streamController.add(testEvents);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(viewModel.events, testEvents);
        verify(mockRepository.getEventsStream()).called(1);
        
        await streamController.close();
      });

      test('should not listen twice if already listening', () {
        // Arrange
        when(mockRepository.getEventsStream())
            .thenAnswer((_) => Stream.value([]));

        // Act
        viewModel.listenEvents();
        viewModel.listenEvents(); // İkinci çağrı

        // Assert
        verify(mockRepository.getEventsStream()).called(1); // Sadece bir kez çağrıldı
      });
    });

    group('addEvent', () {
      test('should add event successfully', () async {
        // Arrange
        when(mockRepository.addEvent(testEvent))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.addEvent(testEvent);

        // Assert
        verify(mockRepository.addEvent(testEvent)).called(1);
        expect(viewModel.error, isNull);
      });

      test('should set error when add event fails', () async {
        // Arrange
        final failure = ServerFailure('Add failed');
        when(mockRepository.addEvent(testEvent))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.addEvent(testEvent);

        // Assert
        expect(viewModel.error, 'Add failed');
      });
    });

    group('updateEvent', () {
      test('should update event successfully', () async {
        // Arrange
        when(mockRepository.updateEvent(testEvent))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.updateEvent(testEvent);

        // Assert
        verify(mockRepository.updateEvent(testEvent)).called(1);
        expect(viewModel.error, isNull);
      });

      test('should set error when update fails', () async {
        // Arrange
        final failure = ServerFailure('Update failed');
        when(mockRepository.updateEvent(testEvent))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.updateEvent(testEvent);

        // Assert
        expect(viewModel.error, 'Update failed');
      });
    });

    group('deleteEvent', () {
      const testEventId = 'event-123';

      test('should delete event successfully', () async {
        // Arrange
        when(mockRepository.deleteEvent(testEventId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.deleteEvent(testEventId);

        // Assert
        verify(mockRepository.deleteEvent(testEventId)).called(1);
        expect(viewModel.error, isNull);
      });

      test('should set error when delete fails', () async {
        // Arrange
        final failure = ServerFailure('Delete failed');
        when(mockRepository.deleteEvent(testEventId))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.deleteEvent(testEventId);

        // Assert
        expect(viewModel.error, 'Delete failed');
      });
    });

    group('joinEvent', () {
      const testUserId = 'user-123';

      test('should join event successfully', () async {
        // Arrange
        when(mockRepository.joinEvent(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.joinEvent(testEvent, testUserId);

        // Assert
        verify(mockRepository.joinEvent(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });

      test('should set error when join fails', () async {
        // Arrange
        final failure = ServerFailure('Join failed');
        when(mockRepository.joinEvent(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.joinEvent(testEvent, testUserId);

        // Assert
        expect(viewModel.error, 'Join failed');
      });
    });

    group('leaveEvent', () {
      const testUserId = 'user-123';

      test('should leave event successfully', () async {
        // Arrange
        when(mockRepository.leaveEvent(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.leaveEvent(testEvent, testUserId);

        // Assert
        verify(mockRepository.leaveEvent(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });

      test('should set error when leave fails', () async {
        // Arrange
        final failure = ServerFailure('Leave failed');
        when(mockRepository.leaveEvent(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.leaveEvent(testEvent, testUserId);

        // Assert
        expect(viewModel.error, 'Leave failed');
      });
    });

    group('loadMore', () {
      test('should load more events successfully', () async {
        // Arrange
        viewModel.events = [testEvent];
        final moreEvents = [
          EventModel(
            id: 'event-2',
            title: 'Event 2',
            description: 'Description 2',
            location: const GeoPoint(41.0082, 28.9784),
            address: 'Address 2',
            datetime: DateTime.now().add(const Duration(days: 2)),
            quota: 20,
            createdBy: 'user-456',
            participants: [],
          ),
        ];
        when(mockRepository.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Either.right(moreEvents));

        // Act
        await viewModel.loadMore();

        // Assert
        expect(viewModel.isLoadingMore, false);
        expect(viewModel.events.length, greaterThan(1));
        verify(mockRepository.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: 50,
        )).called(1);
      });

      test('should not load more if already loading', () async {
        // Arrange
        viewModel.isLoadingMore = true;
        viewModel.events = [testEvent];

        // Act
        await viewModel.loadMore();

        // Assert
        verifyNever(mockRepository.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        ));
      });

      test('should not load more if cannot load more', () async {
        // Arrange
        viewModel.canLoadMore = false;
        viewModel.events = [testEvent];

        // Act
        await viewModel.loadMore();

        // Assert
        verifyNever(mockRepository.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        ));
      });

      test('should set error when load more fails', () async {
        // Arrange
        viewModel.events = [testEvent];
        final failure = ServerFailure('Load more failed');
        when(mockRepository.fetchNextEvents(
          startAfter: anyNamed('startAfter'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.loadMore();

        // Assert
        expect(viewModel.error, 'Load more failed');
        expect(viewModel.isLoadingMore, false);
      });
    });

    group('getUserEventsStream', () {
      const testUserId = 'user-123';
      final testEvents = [testEvent];

      test('should return stream of user events', () async {
        // Arrange
        when(mockRepository.getUserEventsStream(testUserId))
            .thenAnswer((_) => Stream.value(testEvents));

        // Act
        final stream = viewModel.getUserEventsStream(testUserId);

        // Assert
        expect(stream, isA<Stream<List<EventModel>>>());
        final result = await stream.first;
        expect(result, testEvents);
        verify(mockRepository.getUserEventsStream(testUserId)).called(1);
      });
    });

    group('sendJoinRequest', () {
      const testUserId = 'user-123';

      test('should send join request successfully', () async {
        // Arrange
        when(mockRepository.sendJoinRequest(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.sendJoinRequest(testEvent, testUserId);

        // Assert
        verify(mockRepository.sendJoinRequest(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });
    });

    group('approveJoinRequest', () {
      const testUserId = 'user-123';

      test('should approve join request successfully', () async {
        // Arrange
        when(mockRepository.approveJoinRequest(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.approveJoinRequest(testEvent, testUserId);

        // Assert
        verify(mockRepository.approveJoinRequest(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });
    });

    group('rejectJoinRequest', () {
      const testUserId = 'user-123';

      test('should reject join request successfully', () async {
        // Arrange
        when(mockRepository.rejectJoinRequest(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.rejectJoinRequest(testEvent, testUserId);

        // Assert
        verify(mockRepository.rejectJoinRequest(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });
    });

    group('cancelJoinRequest', () {
      const testUserId = 'user-123';

      test('should cancel join request successfully', () async {
        // Arrange
        when(mockRepository.cancelJoinRequest(testEvent.id, testUserId))
            .thenAnswer((_) async => Either.rightVoid());

        // Act
        await viewModel.cancelJoinRequest(testEvent, testUserId);

        // Assert
        verify(mockRepository.cancelJoinRequest(testEvent.id, testUserId)).called(1);
        expect(viewModel.error, isNull);
      });
    });
  });
}

