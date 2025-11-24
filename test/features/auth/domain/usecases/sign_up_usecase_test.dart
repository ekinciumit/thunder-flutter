import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'sign_up_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late SignUpUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpUseCase(mockRepository);
  });

  group('SignUpUseCase', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: testEmail,
    );

    test('should return Right(UserModel) when sign up is successful', () async {
      // Arrange
      when(mockRepository.signUp(testEmail, testPassword))
          .thenAnswer((_) async => Either.right(testUser));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      expect(result.right, testUser);
      verify(mockRepository.signUp(testEmail, testPassword)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Sign up failed');
      when(mockRepository.signUp(testEmail, testPassword))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Sign up failed');
      verify(mockRepository.signUp(testEmail, testPassword)).called(1);
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
      verifyNever(mockRepository.signUp(any, any));
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
      verifyNever(mockRepository.signUp(any, any));
    });

    test('should return Left(ValidationFailure) when password is too short', () async {
      // Arrange
      const shortPassword = '12345'; // 5 karakter, minimum 6 olmalı
      
      // Act
      final result = await useCase.call(testEmail, shortPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Şifre en az 6 karakter olmalıdır');
      verifyNever(mockRepository.signUp(any, any));
    });

    test('should return Right(UserModel) when password is exactly 6 characters', () async {
      // Arrange
      const validPassword = '123456'; // Tam 6 karakter
      when(mockRepository.signUp(testEmail, validPassword))
          .thenAnswer((_) async => Either.right(testUser));

      // Act
      final result = await useCase.call(testEmail, validPassword);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testUser);
      verify(mockRepository.signUp(testEmail, validPassword)).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.signUp(testEmail, testPassword))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.signUp(testEmail, testPassword)).called(1);
    });
  });
}

