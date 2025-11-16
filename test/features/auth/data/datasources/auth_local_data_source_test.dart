import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/exceptions.dart';
import 'dart:convert';

import 'auth_local_data_source_test.mocks.dart';

/// Mock classes için annotation
@GenerateMocks([SharedPreferences])
void main() {
  late AuthLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = AuthLocalDataSourceImpl(prefs: mockPrefs);
  });

  group('cacheUser', () {
    test('should cache user successfully', () async {
      // Arrange
      final user = UserModel(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      final userJson = jsonEncode(user.toMap());

      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await dataSource.cacheUser(user);

      // Assert
      verify(mockPrefs.setString('cached_user', userJson)).called(1);
    });

    test('should throw CacheException when cache fails', () async {
      // Arrange
      final user = UserModel(
        uid: 'test-uid-123',
        email: 'test@example.com',
      );

      when(mockPrefs.setString(any, any)).thenThrow(Exception('Cache failed'));

      // Act & Assert
      expect(
        () => dataSource.cacheUser(user),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('getCachedUser', () {
    test('should return UserModel when cached user exists', () async {
      // Arrange
      final user = UserModel(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      final userMap = user.toMap();
      userMap['uid'] = user.uid; // uid'yi map'e ekle
      final userJson = jsonEncode(userMap);

      when(mockPrefs.getString('cached_user')).thenReturn(userJson);

      // Act
      final result = await dataSource.getCachedUser();

      // Assert
      expect(result, isA<UserModel>());
      expect(result?.uid, user.uid);
      expect(result?.email, user.email);
      verify(mockPrefs.getString('cached_user')).called(1);
    });

    test('should return null when no cached user exists', () async {
      // Arrange
      when(mockPrefs.getString('cached_user')).thenReturn(null);

      // Act
      final result = await dataSource.getCachedUser();

      // Assert
      expect(result, isNull);
      verify(mockPrefs.getString('cached_user')).called(1);
    });

    test('should return null when cached data is invalid', () async {
      // Arrange
      when(mockPrefs.getString('cached_user')).thenReturn('invalid-json');

      // Act
      final result = await dataSource.getCachedUser();

      // Assert
      expect(result, isNull);
    });

    test('should return null when cached user has no uid', () async {
      // Arrange
      final invalidUserMap = {'email': 'test@example.com'};
      final invalidUserJson = jsonEncode(invalidUserMap);

      when(mockPrefs.getString('cached_user')).thenReturn(invalidUserJson);

      // Act
      final result = await dataSource.getCachedUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('clearCache', () {
    test('should clear cache successfully', () async {
      // Arrange
      when(mockPrefs.remove('cached_user')).thenAnswer((_) async => true);

      // Act
      await dataSource.clearCache();

      // Assert
      verify(mockPrefs.remove('cached_user')).called(1);
    });

    test('should throw CacheException when clear fails', () async {
      // Arrange
      when(mockPrefs.remove('cached_user')).thenThrow(Exception('Clear failed'));

      // Act & Assert
      expect(
        () => dataSource.clearCache(),
        throwsA(isA<CacheException>()),
      );
    });
  });
}

