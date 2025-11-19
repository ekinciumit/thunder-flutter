import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/domain/usecases/get_events_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/models/event_model.dart';

import 'get_events_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([EventRepository])
void main() {
  late GetEventsUseCase useCase;
  late MockEventRepository mockRepository;

  setUp(() {
    mockRepository = MockEventRepository();
    useCase = GetEventsUseCase(mockRepository);
  });

  group('GetEventsUseCase', () {
    final testEvents = [
      EventModel(
        id: 'event-1',
        title: 'Event 1',
        description: 'Description 1',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Address 1',
        datetime: DateTime.now().add(const Duration(days: 1)),
        quota: 10,
        createdBy: 'user-1',
        participants: [],
      ),
      EventModel(
        id: 'event-2',
        title: 'Event 2',
        description: 'Description 2',
        location: const GeoPoint(41.0082, 28.9784),
        address: 'Address 2',
        datetime: DateTime.now().add(const Duration(days: 2)),
        quota: 20,
        createdBy: 'user-2',
        participants: [],
      ),
    ];

    test('should return Stream<List<EventModel>> when stream is successful', () async {
      // Arrange
      final streamController = StreamController<List<EventModel>>();
      when(mockRepository.getEventsStream())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call();
      streamController.add(testEvents);

      // Assert
      expect(stream, isA<Stream<List<EventModel>>>());
      final result = await stream.first;
      expect(result, testEvents);
      verify(mockRepository.getEventsStream()).called(1);
      
      await streamController.close();
    });

    test('should emit multiple events when stream emits multiple times', () async {
      // Arrange
      final streamController = StreamController<List<EventModel>>();
      when(mockRepository.getEventsStream())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call();
      streamController.add([testEvents[0]]);
      streamController.add(testEvents);

      // Assert - Stream'i bir kez dinle
      final results = <List<EventModel>>[];
      stream.listen((event) {
        results.add(event);
      });
      
      // Stream'e veri ekle
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results[0], [testEvents[0]]);
      expect(results[1], testEvents);
      
      verify(mockRepository.getEventsStream()).called(1);
      
      await streamController.close();
    });

    test('should return empty list when stream emits empty list', () async {
      // Arrange
      final streamController = StreamController<List<EventModel>>();
      when(mockRepository.getEventsStream())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call();
      streamController.add([]);

      // Assert
      final result = await stream.first;
      expect(result, isEmpty);
      verify(mockRepository.getEventsStream()).called(1);
      
      await streamController.close();
    });
  });
}

