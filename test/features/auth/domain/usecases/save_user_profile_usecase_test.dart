import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/save_user_profile_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'save_user_profile_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late SaveUserProfileUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SaveUserProfileUseCase(mockRepository);
  });

  group('SaveUserProfileUseCase', () {
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: 'test@example.com',
      displayName: 'Test User',
      bio: 'Test bio',
    );

    test('should return Right(void) when save is successful', () async {
      // Arrange
      when(mockRepository.saveUserProfile(testUser))
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call(testUser);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.saveUserProfile(testUser)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ValidationFailure) when uid is empty', () async {
      // Arrange
      final invalidUser = UserModel(
        uid: '', // Boş uid
        email: 'test@example.com',
      );

      // Act
      final result = await useCase.call(invalidUser);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kullanıcı ID boş olamaz');
      verifyNever(mockRepository.saveUserProfile(any));
    });

    test('should return Left(ValidationFailure) when email is empty', () async {
      // Arrange
      final invalidUser = UserModel(
        uid: 'test-uid-123',
        email: '', // Boş email
      );

      // Act
      final result = await useCase.call(invalidUser);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'E-posta boş olamaz');
      verifyNever(mockRepository.saveUserProfile(any));
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Save failed');
      when(mockRepository.saveUserProfile(testUser))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUser);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Save failed');
      verify(mockRepository.saveUserProfile(testUser)).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.saveUserProfile(testUser))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUser);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.saveUserProfile(testUser)).called(1);
    });
  });
}

