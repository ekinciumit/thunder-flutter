import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/search_all_messages_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/message_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'search_all_messages_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late SearchAllMessagesUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = SearchAllMessagesUseCase(mockRepository);
  });

  group('SearchAllMessagesUseCase', () {
    const testUserId = 'user-123';
    const testQuery = 'test query';
    final testMessages = [
      MessageModel(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        senderName: 'User 1',
        text: 'test query found',
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sent,
      ),
    ];

    test('should return Right(List<MessageModel>) when search is successful', () async {
      // Arrange
      when(mockRepository.searchAllMessages(testUserId, testQuery, limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.right(testMessages));

      // Act
      final result = await useCase.call(testUserId, testQuery, limit: 100);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testMessages);
      verify(mockRepository.searchAllMessages(testUserId, testQuery, limit: 100)).called(1);
    });

    test('should return Left(ValidationFailure) when userId is empty', () async {
      // Act
      final result = await useCase.call('', testQuery);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kullanıcı ID boş olamaz');
      verifyNever(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when query is empty', () async {
      // Act
      final result = await useCase.call(testUserId, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Arama sorgusu boş olamaz');
      verifyNever(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when query is only whitespace', () async {
      // Act
      final result = await useCase.call(testUserId, '   ');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Arama sorgusu boş olamaz');
      verifyNever(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is zero', () async {
      // Act
      final result = await useCase.call(testUserId, testQuery, limit: 0);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 0\'dan büyük olmalıdır');
      verifyNever(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ValidationFailure) when limit is greater than 500', () async {
      // Act
      final result = await useCase.call(testUserId, testQuery, limit: 501);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Limit 500\'den küçük olmalıdır');
      verifyNever(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Search all messages failed');
      when(mockRepository.searchAllMessages(any, any, limit: anyNamed('limit')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUserId, testQuery);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Search all messages failed');
    });
  });
}

