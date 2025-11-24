import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/chat/domain/usecases/create_group_chat_usecase.dart';
import 'package:thunder/features/chat/domain/repositories/chat_repository.dart';
import 'package:thunder/models/chat_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'create_group_chat_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([ChatRepository])
void main() {
  late CreateGroupChatUseCase useCase;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    useCase = CreateGroupChatUseCase(mockRepository);
  });

  group('CreateGroupChatUseCase', () {
    const testName = 'Test Group';
    const testCreatedBy = 'user-123';
    final testParticipants = ['user-123', 'user-456'];
    final testChat = ChatModel(
      id: 'chat-123',
      name: testName,
      type: ChatType.group,
      participants: testParticipants,
      createdAt: DateTime.now(),
    );

    test('should return Right(ChatModel) when group chat is created successfully', () async {
      // Arrange
      when(mockRepository.createGroupChat(
        name: anyNamed('name'),
        createdBy: anyNamed('createdBy'),
        participants: anyNamed('participants'),
      )).thenAnswer((_) async => Either.right(testChat));

      // Act
      final result = await useCase.call(
        name: testName,
        createdBy: testCreatedBy,
        participants: testParticipants,
      );

      // Assert
      expect(result.isRight, true);
      expect(result.right, testChat);
      verify(mockRepository.createGroupChat(
        name: testName,
        createdBy: testCreatedBy,
        participants: testParticipants,
      )).called(1);
    });

    test('should return Left(ValidationFailure) when name is empty', () async {
      // Act
      final result = await useCase.call(
        name: '',
        createdBy: testCreatedBy,
        participants: testParticipants,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Grup adı boş olamaz');
      verifyNever(mockRepository.createGroupChat(name: anyNamed('name'), createdBy: anyNamed('createdBy'), participants: anyNamed('participants'), description: anyNamed('description'), photoUrl: anyNamed('photoUrl')));
    });

    test('should return Left(ValidationFailure) when createdBy is empty', () async {
      // Act
      final result = await useCase.call(
        name: testName,
        createdBy: '',
        participants: testParticipants,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Oluşturan kullanıcı ID\'si boş olamaz');
      verifyNever(mockRepository.createGroupChat(name: anyNamed('name'), createdBy: anyNamed('createdBy'), participants: anyNamed('participants'), description: anyNamed('description'), photoUrl: anyNamed('photoUrl')));
    });

    test('should return Left(ValidationFailure) when participants is empty', () async {
      // Act
      final result = await useCase.call(
        name: testName,
        createdBy: testCreatedBy,
        participants: [],
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'En az bir katılımcı olmalıdır');
      verifyNever(mockRepository.createGroupChat(name: anyNamed('name'), createdBy: anyNamed('createdBy'), participants: anyNamed('participants'), description: anyNamed('description'), photoUrl: anyNamed('photoUrl')));
    });

    test('should return Left(ValidationFailure) when createdBy is not in participants', () async {
      // Act
      final result = await useCase.call(
        name: testName,
        createdBy: testCreatedBy,
        participants: ['user-456'], // createdBy yok
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Oluşturan kullanıcı katılımcılar arasında olmalıdır');
      verifyNever(mockRepository.createGroupChat(name: anyNamed('name'), createdBy: anyNamed('createdBy'), participants: anyNamed('participants'), description: anyNamed('description'), photoUrl: anyNamed('photoUrl')));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Create group chat failed');
      when(mockRepository.createGroupChat(name: anyNamed('name'), createdBy: anyNamed('createdBy'), participants: anyNamed('participants'), description: anyNamed('description'), photoUrl: anyNamed('photoUrl')))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(
        name: testName,
        createdBy: testCreatedBy,
        participants: testParticipants,
      );

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Create group chat failed');
    });
  });
}

