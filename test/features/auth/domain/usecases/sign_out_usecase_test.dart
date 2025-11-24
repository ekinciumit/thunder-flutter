import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/core/errors/failures.dart';

import 'sign_out_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  group('SignOutUseCase', () {
    test('should return Right(void) when sign out is successful', () async {
      // Arrange
      when(mockRepository.signOut())
          .thenAnswer((_) async => Either.rightVoid());

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      verify(mockRepository.signOut()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Sign out failed');
      when(mockRepository.signOut())
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Sign out failed');
      verify(mockRepository.signOut()).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.signOut())
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call();

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.signOut()).called(1);
    });
  });
}

