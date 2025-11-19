import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/fetch_user_profile_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'fetch_user_profile_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late FetchUserProfileUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = FetchUserProfileUseCase(mockRepository);
  });

  group('FetchUserProfileUseCase', () {
    const testUid = 'test-uid-123';
    final testUser = UserModel(
      uid: testUid,
      email: 'test@example.com',
      displayName: 'Test User',
    );

    test('should return Right(UserModel) when fetch is successful', () async {
      // Arrange
      when(mockRepository.fetchUserProfile(testUid))
          .thenAnswer((_) async => Either.right(testUser));

      // Act
      final result = await useCase.call(testUid);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      expect(result.right, testUser);
      verify(mockRepository.fetchUserProfile(testUid)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Left(ServerFailure) when repository returns failure', () async {
      // Arrange
      final failure = ServerFailure('Fetch failed');
      when(mockRepository.fetchUserProfile(testUid))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUid);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      expect(result.left.message, 'Fetch failed');
      verify(mockRepository.fetchUserProfile(testUid)).called(1);
    });

    test('should return Left(NetworkFailure) when repository returns NetworkFailure', () async {
      // Arrange
      final failure = NetworkFailure('Network error');
      when(mockRepository.fetchUserProfile(testUid))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUid);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<NetworkFailure>());
      expect(result.left.message, 'Network error');
      verify(mockRepository.fetchUserProfile(testUid)).called(1);
    });

    test('should return Left(CacheFailure) when repository returns CacheFailure', () async {
      // Arrange
      final failure = CacheFailure('Cache error');
      when(mockRepository.fetchUserProfile(testUid))
          .thenAnswer((_) async => Either.left(failure));

      // Act
      final result = await useCase.call(testUid);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<CacheFailure>());
      expect(result.left.message, 'Cache error');
      verify(mockRepository.fetchUserProfile(testUid)).called(1);
    });

    test('should return Left(ValidationFailure) when uid is empty', () async {
      // Arrange
      const emptyUid = '';

      // Act
      final result = await useCase.call(emptyUid);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ValidationFailure>());
      expect(result.left.message, 'Kullanıcı ID boş olamaz');
      verifyNever(mockRepository.fetchUserProfile(any));
    });
  });
}

