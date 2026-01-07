import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thunder/features/event/domain/usecases/get_events_usecase.dart';
import 'package:thunder/features/event/domain/repositories/event_repository.dart';
import 'package:thunder/features/event/data/models/event_model.dart';
import 'package:thunder/features/event/domain/entities/event_entity.dart';
import 'package:thunder/features/event/data/mappers/event_mapper.dart';

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
    final testEventsModel = [
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
    final testEvents = EventMapper.toEntityList(testEventsModel);

    test('should return Stream<List<EventEntity>> when stream is successful', () async {
      // Arrange
      final streamController = StreamController<List<EventEntity>>();
      when(mockRepository.getEventsStream())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call();
      streamController.add(testEvents);

      // Assert
      expect(stream, isA<Stream<List<EventEntity>>>());
      final result = await stream.first;
      expect(result.length, testEvents.length);
      expect(result.first.id, testEvents.first.id);
      verify(mockRepository.getEventsStream()).called(1);
      
      await streamController.close();
    });

    test('should emit multiple events when stream emits multiple times', () async {
      // Arrange
      final streamController = StreamController<List<EventEntity>>();
      when(mockRepository.getEventsStream())
          .thenAnswer((_) => streamController.stream);

      // Act
      final stream = useCase.call();
      streamController.add([testEvents[0]]);
      streamController.add(testEvents);

      // Assert - Stream'i bir kez dinle
      final results = <List<EventEntity>>[];
      stream.listen((event) {
        results.add(event);
      });
      
      // Stream'e veri ekle
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(results.length, greaterThanOrEqualTo(2));
      expect(results[0].length, 1);
      expect(results[0].first.id, testEvents[0].id);
      expect(results[1].length, testEvents.length);
      expect(results[1].first.id, testEvents.first.id);
      
      verify(mockRepository.getEventsStream()).called(1);
      
      await streamController.close();
    });

    test('should return empty list when stream emits empty list', () async {
      // Arrange
      final streamController = StreamController<List<EventEntity>>();
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

