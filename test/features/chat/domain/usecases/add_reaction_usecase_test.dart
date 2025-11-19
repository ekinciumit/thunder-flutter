import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/add_reaction_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'add_reaction_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late AddReactionUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = AddReactionUseCase(mockRepository);
  });

  group('AddReactionUseCase', () {
    const testMessageId = 'msg-123';
    const testUserId = 'user-123';
    const testEmoji = '👍';

    test('should return Right(void) when reaction is added successfully', () async {
      // Arrange
      when(mockRepository.addReaction(testMessageId, testUserId, testEmoji))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testMessageId, testUserId, testEmoji);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.addReaction(testMessageId, testUserId, testEmoji)).called(1);
    });

    test('should return Left(ValidationFailure) when messageId is empty', () async {
      // Act
      final result = await useCase.call('', testUserId, testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.addReaction(any, any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, '', testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.addReaction(any, any, any));
    });

    test('should return Left(ValidationFailure) when emoji is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, testUserId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.addReaction(any, any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Add reaction failed');
      when(mockRepository.addReaction(testMessageId, testUserId, testEmoji))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testMessageId, testUserId, testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Add reaction failed');
    });
  });
}

