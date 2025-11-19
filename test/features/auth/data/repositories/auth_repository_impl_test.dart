import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:thunder/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:thunder/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/exceptions.dart';
import 'package:thunder/core/errors/failures.dart';

import 'auth_repository_impl_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([
  AuthRemoteDataSource,
  AuthLocalDataSource,
])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('signIn', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: testEmail,
    );

    test('should return Right(UserModel) when sign in is successful', () async {
      // Arrange
      when(mockRemoteDataSource.signIn(testEmail, testPassword))
          .thenAnswer((_) async => testUser);
      when(mockLocalDataSource.cacheUser(testUser))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.signIn(testEmail, testPassword);

      // Assert
      expect(result.isRight, true);
      expect(result.isLeft, false);
      expect(result.right, testUser);
      verify(mockRemoteDataSource.signIn(testEmail, testPassword)).called(1);
      verify(mockLocalDataSource.cacheUser(testUser)).called(1);
    });

    test('should return Left(ServerFailure) when remote sign in fails', () async {
      // Arrange
      when(mockRemoteDataSource.signIn(testEmail, testPassword))
          .thenThrow(ServerException('Sign in failed'));

      // Act
      final result = await repository.signIn(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.isRight, false);
      expect(result.left, isA<ServerFailure>());
      verify(mockRemoteDataSource.signIn(testEmail, testPassword)).called(1);
      verifyNever(mockLocalDataSource.cacheUser(any));
    });

    test('should return Right(UserModel) when cache fails but sign in succeeds (cache error is non-critical)', () async {
      // Arrange
      when(mockRemoteDataSource.signIn(testEmail, testPassword))
          .thenAnswer((_) async => testUser);
      when(mockLocalDataSource.cacheUser(testUser))
          .thenThrow(CacheException('Cache failed'));

      // Act
      final result = await repository.signIn(testEmail, testPassword);

      // Assert
      // Cache hatası kritik değil, kullanıcı zaten giriş yaptı
      // Bu yüzden Right(UserModel) döndürmeli
      expect(result.isRight, true);
      expect(result.right, testUser);
      verify(mockRemoteDataSource.signIn(testEmail, testPassword)).called(1);
      verify(mockLocalDataSource.cacheUser(testUser)).called(1);
    });
  });

  group('signUp', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: testEmail,
    );

    test('should return Right(UserModel) when sign up is successful', () async {
      // Arrange
      when(mockRemoteDataSource.signUp(testEmail, testPassword))
          .thenAnswer((_) async => testUser);
      when(mockLocalDataSource.cacheUser(testUser))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.signUp(testEmail, testPassword);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testUser);
      verify(mockRemoteDataSource.signUp(testEmail, testPassword)).called(1);
      verify(mockLocalDataSource.cacheUser(testUser)).called(1);
    });

    test('should return Left(ServerFailure) when remote sign up fails', () async {
      // Arrange
      when(mockRemoteDataSource.signUp(testEmail, testPassword))
          .thenThrow(ServerException('Sign up failed'));

      // Act
      final result = await repository.signUp(testEmail, testPassword);

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
    });
  });

  group('signOut', () {
    test('should return Right(void) when sign out is successful', () async {
      // Arrange
      when(mockRemoteDataSource.signOut())
          .thenAnswer((_) async => Future.value());
      when(mockLocalDataSource.clearCache())
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result.isRight, true);
      verify(mockRemoteDataSource.signOut()).called(1);
      verify(mockLocalDataSource.clearCache()).called(1);
    });

    test('should return Left(ServerFailure) when sign out fails', () async {
      // Arrange
      when(mockRemoteDataSource.signOut())
          .thenThrow(ServerException('Sign out failed'));

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      verifyNever(mockLocalDataSource.clearCache());
    });
  });

  group('fetchUserProfile', () {
    const testUid = 'test-uid-123';
    final testUser = UserModel(
      uid: testUid,
      email: 'test@example.com',
    );

    test('should return Right(UserModel) from cache when available', () async {
      // Arrange
      when(mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => testUser);

      // Act
      final result = await repository.fetchUserProfile(testUid);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testUser);
      verify(mockLocalDataSource.getCachedUser()).called(1);
      verifyNever(mockRemoteDataSource.fetchUserProfile(any));
    });

    test('should return Right(UserModel) from remote when cache is empty', () async {
      // Arrange
      when(mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => null);
      when(mockRemoteDataSource.fetchUserProfile(testUid))
          .thenAnswer((_) async => testUser);
      when(mockLocalDataSource.cacheUser(testUser))
          .thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.fetchUserProfile(testUid);

      // Assert
      expect(result.isRight, true);
      expect(result.right, testUser);
      verify(mockLocalDataSource.getCachedUser()).called(1);
      verify(mockRemoteDataSource.fetchUserProfile(testUid)).called(1);
      verify(mockLocalDataSource.cacheUser(testUser)).called(1);
    });

    test('should return Left(ServerFailure) when remote fails and cache is empty', () async {
      // Arrange
      when(mockLocalDataSource.getCachedUser())
          .thenAnswer((_) async => null);
      when(mockRemoteDataSource.fetchUserProfile(testUid))
          .thenThrow(ServerException('Fetch failed'));

      // Act
      final result = await repository.fetchUserProfile(testUid);

      // Assert
      // Mevcut implementasyonda remote hata verdiğinde cache'i tekrar kontrol ediyoruz (offline support)
      // Bu yüzden getCachedUser 2 kez çağrılıyor: bir kez başta, bir kez catch'te
      expect(result.isLeft, true);
      expect(result.left, isA<ServerFailure>());
      verify(mockLocalDataSource.getCachedUser()).called(greaterThan(1)); // En az 2 kez çağrılıyor
      verify(mockRemoteDataSource.fetchUserProfile(testUid)).called(1);
    });
  });

  group('getCurrentUser', () {
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: 'test@example.com',
    );

    test('should return UserModel when user is logged in', () {
      // Arrange
      when(mockRemoteDataSource.getCurrentUser()).thenReturn(testUser);

      // Act
      final result = repository.getCurrentUser();

      // Assert
      expect(result, testUser);
      verify(mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return null when user is not logged in', () {
      // Arrange
      when(mockRemoteDataSource.getCurrentUser()).thenReturn(null);

      // Act
      final result = repository.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });
}

