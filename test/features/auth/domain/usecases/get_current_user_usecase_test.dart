import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:thunder/features/auth/domain/repositories/auth_repository.dart';
import 'package:thunder/models/user_model.dart';

import 'get_current_user_usecase_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([AuthRepository])
void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  group('GetCurrentUserUseCase', () {
    final testUser = UserModel(
      uid: 'test-uid-123',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    test('should return UserModel when user is logged in', () {
      // Arrange
      when(mockRepository.getCurrentUser()).thenReturn(testUser);

      // Act
      final result = useCase.call();

      // Assert
      expect(result, testUser);
      verify(mockRepository.getCurrentUser()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return null when user is not logged in', () {
      // Arrange
      when(mockRepository.getCurrentUser()).thenReturn(null);

      // Act
      final result = useCase.call();

      // Assert
      expect(result, isNull);
      verify(mockRepository.getCurrentUser()).called(1);
    });
  });
}

