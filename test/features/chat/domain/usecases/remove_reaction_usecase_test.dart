import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/remove_reaction_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'remove_reaction_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late RemoveReactionUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = RemoveReactionUseCase(mockRepository);
  });

  group('RemoveReactionUseCase', () {
    const testMessageId = 'msg-123';
    const testUserId = 'user-123';
    const testEmoji = '👍';

    test('should return Right(void) when reaction is removed successfully', () async {
      // Arrange
      when(mockRepository.removeReaction(testMessageId, testUserId, testEmoji))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testMessageId, testUserId, testEmoji);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.removeReaction(testMessageId, testUserId, testEmoji)).called(1);
    });

    test('should return Left(ValidationFailure) when messageId is empty', () async {
      // Act
      final result = await useCase.call('', testUserId, testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.removeReaction(any, any, any));
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, '', testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.removeReaction(any, any, any));
    });

    test('should return Left(ValidationFailure) when emoji is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, testUserId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID, kullanıcı ID ve emoji boş olamaz');
      verifyNever(mockRepository.removeReaction(any, any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Remove reaction failed');
      when(mockRepository.removeReaction(testMessageId, testUserId, testEmoji))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testMessageId, testUserId, testEmoji);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Remove reaction failed');
    });
  });
}

