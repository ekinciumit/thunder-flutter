import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/failures.dart';

import 'auth_viewmodel_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late AuthViewModel viewModel;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    // getCurrentUser her zaman çağrılıyor (constructor'da)
    when(mockRepository.getCurrentUser()).thenReturn(null);
    viewModel = AuthViewModel(authRepository: mockRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('AuthViewModel', () {
    group('Initialization', () {
      test('should initialize with current user from repository', () {
        // Arrange
        final testUser = UserModel(uid: 'test-uid', email: 'test@test.com');
        final testMockRepository = MockAuthRepository();
        when(testMockRepository.getCurrentUser()).thenReturn(testUser);

        // Act
        final newViewModel = AuthViewModel(authRepository: testMockRepository);

        // Assert
        expect(newViewModel.user, testUser);
        verify(testMockRepository.getCurrentUser()).called(1);
        
        newViewModel.dispose();
      });

      test('should initialize with null user when repository returns null', () {
        // Arrange
        final testMockRepository = MockAuthRepository();
        when(testMockRepository.getCurrentUser()).thenReturn(null);

        // Act
        final newViewModel = AuthViewModel(authRepository: testMockRepository);

        // Assert
        expect(newViewModel.user, isNull);
        verify(testMockRepository.getCurrentUser()).called(1);
        
        newViewModel.dispose();
      });
    });

    group('signIn', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';
      final testUser = UserModel(uid: 'test-uid', email: testEmail);
      final testFullUser = UserModel(
        uid: 'test-uid',
        email: testEmail,
        displayName: 'Test User',
      );

      test('should sign in successfully and fetch profile', () async {
        // Arrange
        when(mockRepository.signIn(testEmail, testPassword))
            .thenAnswer((_) async => Either.right(testUser));
        when(mockRepository.fetchUserProfile(testUser.uid))
            .thenAnswer((_) async => Either.right(testFullUser));

        // Act
        await viewModel.signIn(testEmail, testPassword);

        // Assert
        expect(viewModel.user, testFullUser);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.needsProfileCompletion, false);
        verify(mockRepository.signIn(testEmail, testPassword)).called(1);
        verify(mockRepository.fetchUserProfile(testUser.uid)).called(1);
      });

      test('should sign in successfully when profile fetch fails', () async {
        // Arrange
        when(mockRepository.signIn(testEmail, testPassword))
            .thenAnswer((_) async => Either.right(testUser));
        when(mockRepository.fetchUserProfile(testUser.uid))
            .thenAnswer((_) async => Either.left(ServerFailure('Profile not found')));

        // Act
        await viewModel.signIn(testEmail, testPassword);

        // Assert
        expect(viewModel.user, testUser);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.needsProfileCompletion, true);
      });

      test('should set error when sign in fails', () async {
        // Arrange
        final failure = ServerFailure('Sign in failed');
        when(mockRepository.signIn(testEmail, testPassword))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.signIn(testEmail, testPassword);

        // Assert
        expect(viewModel.user, isNull);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, 'Sign in failed');
        verify(mockRepository.signIn(testEmail, testPassword)).called(1);
        verifyNever(mockRepository.fetchUserProfile(any));
      });

      test('should handle exceptions during sign in', () async {
        // Arrange
        when(mockRepository.signIn(testEmail, testPassword))
            .thenThrow(Exception('Network error'));

        // Act
        await viewModel.signIn(testEmail, testPassword);

        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNotNull);
      });
    });

    group('signUp', () {
      const testEmail = 'test@example.com';
      const testPassword = 'password123';
      final testUser = UserModel(uid: 'test-uid', email: testEmail);

      test('should sign up successfully and set flags', () async {
        // Arrange
        when(mockRepository.signUp(testEmail, testPassword))
            .thenAnswer((_) async => Either.right(testUser));
        when(mockRepository.fetchUserProfile(testUser.uid))
            .thenAnswer((_) async => Either.left(ServerFailure('Profile not found')));

        // Act
        await viewModel.signUp(testEmail, testPassword);

        // Assert
        expect(viewModel.user, testUser);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.needsProfileCompletion, true);
        expect(viewModel.justSignedUp, true);
        verify(mockRepository.signUp(testEmail, testPassword)).called(1);
      });

      test('should set error when sign up fails', () async {
        // Arrange
        final failure = ServerFailure('Sign up failed');
        when(mockRepository.signUp(testEmail, testPassword))
            .thenAnswer((_) async => Either.left(failure));

        // Act
        await viewModel.signUp(testEmail, testPassword);

        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.error, 'Sign up failed');
        expect(viewModel.justSignedUp, false);
      });
    });

    group('completeProfile', () {
      final testUser = UserModel(
        uid: 'test-uid',
        email: 'test@test.com',
        username: 'testuser',
      );

      setUp(() {
        viewModel.user = testUser;
        viewModel.needsProfileCompletion = true; // Başlangıç durumu
      });

      test('should complete profile successfully', () async {
        // Arrange
        final updatedUser = testUser.copyWith(
          displayName: 'Test User',
          bio: 'Test bio',
        );
        when(mockRepository.saveUserProfile(any))
            .thenAnswer((_) async => Either.right(null));

        // Act
        await viewModel.completeProfile(
          displayName: 'Test User',
          bio: 'Test bio',
        );

        // Assert
        expect(viewModel.user?.displayName, 'Test User');
        expect(viewModel.user?.bio, 'Test bio');
        expect(viewModel.needsProfileCompletion, false);
        expect(viewModel.error, isNull);
        verify(mockRepository.saveUserProfile(any)).called(1);
      });

      test('should not complete profile when user is null', () async {
        // Arrange
        viewModel.user = null;

        // Act
        await viewModel.completeProfile(displayName: 'Test User');

        // Assert
        verifyNever(mockRepository.saveUserProfile(any));
      });

      test('should set error when profile save fails', () async {
        // Arrange
        final failure = ServerFailure('Save failed');
        when(mockRepository.saveUserProfile(any))
            .thenAnswer((_) async => Either.left(failure));

        // Act & Assert
        try {
          await viewModel.completeProfile(displayName: 'Test User');
          fail('Should have thrown exception');
        } catch (e) {
          expect(viewModel.error, contains('Save failed'));
          expect(viewModel.needsProfileCompletion, true);
        }
      });
    });

    group('signOut', () {
      setUp(() {
        viewModel.user = UserModel(uid: 'test-uid', email: 'test@test.com');
      });

      test('should sign out successfully', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Either.right(null));

        // Act
        await viewModel.signOut();

        // Assert
        expect(viewModel.user, isNull);
        expect(viewModel.error, isNull);
        verify(mockRepository.signOut()).called(1);
      });

      test('should clear user even when sign out fails', () async {
        // Arrange
        final failure = ServerFailure('Sign out failed');
        when(mockRepository.signOut())
            .thenAnswer((_) async => Either.left(failure));

        // Act & Assert
        try {
          await viewModel.signOut();
          fail('Should have thrown exception');
        } catch (e) {
          expect(viewModel.user, isNull);
          expect(viewModel.error, contains('Sign out failed'));
        }
      });

      test('should clear user on exception', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenThrow(Exception('Network error'));

        // Act & Assert
        try {
          await viewModel.signOut();
          fail('Should have thrown exception');
        } catch (e) {
          expect(viewModel.user, isNull);
        }
      });
    });

    group('loadUserProfile', () {
      final testUser = UserModel(uid: 'test-uid', email: 'test@test.com');
      final testFullUser = UserModel(
        uid: 'test-uid',
        email: 'test@test.com',
        displayName: 'Test User',
      );

      test('should load user profile successfully', () async {
        // Arrange
        viewModel.user = testUser;
        when(mockRepository.fetchUserProfile(testUser.uid))
            .thenAnswer((_) async => Either.right(testFullUser));

        // Act
        await viewModel.loadUserProfile();

        // Assert
        expect(viewModel.user, testFullUser);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        verify(mockRepository.fetchUserProfile(testUser.uid)).called(1);
      });

      test('should not load profile when user is null', () async {
        // Arrange
        viewModel.user = null;

        // Act
        await viewModel.loadUserProfile();

        // Assert
        verifyNever(mockRepository.fetchUserProfile(any));
      });

      test('should handle profile fetch failure silently', () async {
        // Arrange
        viewModel.user = testUser;
        when(mockRepository.fetchUserProfile(testUser.uid))
            .thenAnswer((_) async => Either.left(ServerFailure('Not found')));

        // Act
        await viewModel.loadUserProfile();

        // Assert
        expect(viewModel.user, testUser); // Unchanged
        expect(viewModel.isLoading, false);
      });
    });

    group('fetchUserProfile', () {
      const testUid = 'test-uid';
      final testUser = UserModel(
        uid: testUid,
        email: 'test@test.com',
        displayName: 'Test User',
      );

      test('should fetch user profile successfully', () async {
        // Arrange
        when(mockRepository.fetchUserProfile(testUid))
            .thenAnswer((_) async => Either.right(testUser));

        // Act
        final result = await viewModel.fetchUserProfile(testUid);

        // Assert
        expect(result, testUser);
        verify(mockRepository.fetchUserProfile(testUid)).called(1);
      });

      test('should return null when profile fetch fails', () async {
        // Arrange
        when(mockRepository.fetchUserProfile(testUid))
            .thenAnswer((_) async => Either.left(ServerFailure('Not found')));

        // Act
        final result = await viewModel.fetchUserProfile(testUid);

        // Assert
        expect(result, isNull);
      });

      test('should return null on exception', () async {
        // Arrange
        when(mockRepository.fetchUserProfile(testUid))
            .thenThrow(Exception('Network error'));

        // Act
        final result = await viewModel.fetchUserProfile(testUid);

        // Assert
        expect(result, isNull);
      });
    });

    group('saveUserToken', () {
      const testToken = 'fcm-token-123';

      test('should save user token successfully', () async {
        // Arrange
        when(mockRepository.saveUserToken(testToken))
            .thenAnswer((_) async => Either.right(null));

        // Act
        await viewModel.saveUserToken(testToken);

        // Assert
        verify(mockRepository.saveUserToken(testToken)).called(1);
      });

      test('should handle token save failure silently', () async {
        // Arrange
        when(mockRepository.saveUserToken(testToken))
            .thenAnswer((_) async => Either.left(ServerFailure('Save failed')));

        // Act
        await viewModel.saveUserToken(testToken);

        // Assert
        // Should not throw, should handle silently
        verify(mockRepository.saveUserToken(testToken)).called(1);
      });

      test('should handle exception silently', () async {
        // Arrange
        when(mockRepository.saveUserToken(testToken))
            .thenThrow(Exception('Network error'));

        // Act
        await viewModel.saveUserToken(testToken);

        // Assert
        // Should not throw, should handle silently
      });
    });
  });
}

