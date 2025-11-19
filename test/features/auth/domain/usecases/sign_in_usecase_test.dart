import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'sign_in_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  group('SignInUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: testEmail,
    );

    test('should return Right(UserModel) when sign in is successful', () async {
      // Arrange
      when(mockRepository.signIn(testEmail, testPassword))
          .thenAnswer((_) async => Either.right(testUser));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      expect(result.right, testUser);
      verify(mockRepository.signIn(testEmail, testPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Sign in failed');
      when(mockRepository.signIn(testEmail, testPassword))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Sign in failed');
      verify(mockRepository.signIn(testEmail, testPassword)).called(1);
    });

    test('should return Left(ValidationFailure) when email is empty', () async {
      // Arrange
      const emptyEmail = '';
      
      // Act
      final result = await useCase.call(emptyEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'E-posta ve şifre boş olamaz');
      verifyNever(mockRepository.signIn(any, any));
    });

    test('should return Left(ValidationFailure) when password is empty', () async {
      // Arrange
      const emptyPassword = '';
      
      // Act
      final result = await useCase.call(testEmail, emptyPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'E-posta ve şifre boş olamaz');
      verifyNever(mockRepository.signIn(any, any));
    });

    test('should return Left(ValidationFailure) when both email and password are empty', () async {
      // Arrange
      const emptyEmail = '';
      const emptyPassword = '';
      
      // Act
      final result = await useCase.call(emptyEmail, emptyPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'E-posta ve şifre boş olamaz');
      verifyNever(mockRepository.signIn(any, any));
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.signIn(testEmail, testPassword))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.signIn(testEmail, testPassword)).called(1);
    });
  });
}

