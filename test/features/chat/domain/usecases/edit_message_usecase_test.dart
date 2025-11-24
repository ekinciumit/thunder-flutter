import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/edit_message_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'edit_message_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late EditMessageUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = EditMessageUseCase(mockRepository);
  });

  group('EditMessageUseCase', () {
    const testMessageId = 'msg-123';
    const testNewText = 'Updated message';

    test('should return Right(void) when message is edited successfully', () async {
      // Arrange
      when(mockRepository.editMessage(testMessageId, testNewText))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testMessageId, testNewText);

      // Assert
      expect(result.isRight, true);
      verify(mockRepository.editMessage(testMessageId, testNewText)).called(1);
    });

    test('should return Left(ValidationFailure) when messageId is empty', () async {
      // Act
      final result = await useCase.call('', testNewText);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Mesaj ID boş olamaz');
      verifyNever(mockRepository.editMessage(any, any));
    });

    test('should return Left(ValidationFailure) when newText is empty', () async {
      // Act
      final result = await useCase.call(testMessageId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Yeni metin boş olamaz');
      verifyNever(mockRepository.editMessage(any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Edit message failed');
      when(mockRepository.editMessage(testMessageId, testNewText))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testMessageId, testNewText);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Edit message failed');
    });
  });
}

