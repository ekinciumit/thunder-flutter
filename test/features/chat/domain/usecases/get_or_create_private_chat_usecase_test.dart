import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/get_or_create_private_chat_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/chat_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'get_or_create_private_chat_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late GetOrCreatePrivateChatUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = GetOrCreatePrivateChatUseCase(mockRepository);
  });

  group('GetOrCreatePrivateChatUseCase', () {
    const testUserA = 'user-a';
    const testUserB = 'user-b';
    final testChat = ChatModel(
      id: 'chat-123',
      name: 'Private Chat',
      type: ChatType.private,
      participants: [testUserA, testUserB],
      createdAt: DateTime.now(),
    );

    test('should return Right(ChatModel) when chat is created successfully', () async {
      // Arrange
      when(mockRepository.getOrCreatePrivateChat(testUserA, testUserB))
          .thenAnswer((_) async => Either.right(testChat));

      // Act
      final result = await useCase.call(testUserA, testUserB);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testChat);
      verify(mockRepository.getOrCreatePrivateChat(testUserA, testUserB)).called(1);
    });

    test('should return Left(ValidationFailure) when userA is empty', () async {
      // Act
      final result = await useCase.call('', testUserB);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kullanıcı ID\'leri boş olamaz');
      verifyNever(mockRepository.getOrCreatePrivateChat(any, any));
    });

    test('should return Left(ValidationFailure) when userB is empty', () async {
      // Act
      final result = await useCase.call(testUserA, '');

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kullanıcı ID\'leri boş olamaz');
      verifyNever(mockRepository.getOrCreatePrivateChat(any, any));
    });

    test('should return Left(ValidationFailure) when userA equals userB', () async {
      // Act
      final result = await useCase.call(testUserA, testUserA);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Aynı kullanıcı ile sohbet oluşturulamaz');
      verifyNever(mockRepository.getOrCreatePrivateChat(any, any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Get or create chat failed');
      when(mockRepository.getOrCreatePrivateChat(testUserA, testUserB))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUserA, testUserB);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Get or create chat failed');
    });
  });
}

