import 'package:flutter_test/flutter_test.dart';
import 'package:thunder/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with all fields', () {
      // Arrange
      const uid = 'user-123';
      const email = 'test@test.com';
      const displayName = 'Test User';
      const username = 'testuser';
      const bio = 'Test bio';
      const photoUrl = 'https://example.com/photo.jpg';
      final followers = ['follower1', 'follower2'];
      final following = ['following1'];
      final fcmTokens = ['token1', 'token2'];

      // Act
      final user = UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        username: username,
        bio: bio,
        photoUrl: photoUrl,
        followers: followers,
        following: following,
        fcmTokens: fcmTokens,
      );

      // Assert
      expect(user.uid, uid);
      expect(user.email, email);
      expect(user.displayName, displayName);
      expect(user.username, username);
      expect(user.bio, bio);
      expect(user.photoUrl, photoUrl);
      expect(user.followers, followers);
      expect(user.following, following);
      expect(user.fcmTokens, fcmTokens);
    });

    test('should create UserModel with minimal fields', () {
      // Arrange
      const uid = 'user-123';
      const email = 'test@test.com';

      // Act
      final user = UserModel(
        uid: uid,
        email: email,
      );

      // Assert
      expect(user.uid, uid);
      expect(user.email, email);
      expect(user.displayName, isNull);
      expect(user.username, isNull);
      expect(user.bio, isNull);
      expect(user.photoUrl, isNull);
      expect(user.followers, isEmpty);
      expect(user.following, isEmpty);
      expect(user.fcmTokens, isEmpty);
    });

    group('fromMap', () {
      test('should create UserModel from map with all fields', () {
        // Arrange
        const id = 'user-123';
        final map = {
          'email': 'test@test.com',
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': 'Test bio',
          'photoUrl': 'https://example.com/photo.jpg',
          'followers': ['follower1', 'follower2'],
          'following': ['following1'],
          'fcmTokens': ['token1', 'token2'],
        };

        // Act
        final user = UserModel.fromMap(map, id);

        // Assert
        expect(user.uid, id);
        expect(user.email, map['email']);
        expect(user.displayName, map['displayName']);
        expect(user.username, map['username']);
        expect(user.bio, map['bio']);
        expect(user.photoUrl, map['photoUrl']);
        expect(user.followers, map['followers']);
        expect(user.following, map['following']);
        expect(user.fcmTokens, map['fcmTokens']);
      });

      test('should create UserModel from map with minimal fields', () {
        // Arrange
        const id = 'user-123';
        final map = {
          'email': 'test@test.com',
        };

        // Act
        final user = UserModel.fromMap(map, id);

        // Assert
        expect(user.uid, id);
        expect(user.email, map['email']);
        expect(user.displayName, isNull);
        expect(user.username, isNull);
        expect(user.bio, isNull);
        expect(user.photoUrl, isNull);
        expect(user.followers, isEmpty);
        expect(user.following, isEmpty);
        expect(user.fcmTokens, isEmpty);
      });

      test('should handle null optional fields', () {
        // Arrange
        const id = 'user-123';
        final map = {
          'email': 'test@test.com',
          'displayName': null,
          'username': null,
          'bio': null,
          'photoUrl': null,
        };

        // Act
        final user = UserModel.fromMap(map, id);

        // Assert
        expect(user.uid, id);
        expect(user.email, 'test@test.com');
        expect(user.displayName, isNull);
        expect(user.username, isNull);
        expect(user.bio, isNull);
        expect(user.photoUrl, isNull);
      });

      test('should handle empty email with default', () {
        // Arrange
        const id = 'user-123';
        final map = <String, dynamic>{};

        // Act
        final user = UserModel.fromMap(map, id);

        // Assert
        expect(user.uid, id);
        expect(user.email, '');
      });
    });

    group('toMap', () {
      test('should convert UserModel to map with all fields', () {
        // Arrange
        final user = UserModel(
          uid: 'user-123',
          email: 'test@test.com',
          displayName: 'Test User',
          username: 'testuser',
          bio: 'Test bio',
          photoUrl: 'https://example.com/photo.jpg',
          followers: ['follower1', 'follower2'],
          following: ['following1'],
          fcmTokens: ['token1', 'token2'],
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['email'], user.email);
        expect(map['displayName'], user.displayName);
        expect(map['username'], user.username);
        expect(map['bio'], user.bio);
        expect(map['photoUrl'], user.photoUrl);
        expect(map['followers'], user.followers);
        expect(map['following'], user.following);
        expect(map['fcmTokens'], user.fcmTokens);
      });

      test('should convert UserModel to map with minimal fields', () {
        // Arrange
        final user = UserModel(
          uid: 'user-123',
          email: 'test@test.com',
        );

        // Act
        final map = user.toMap();

        // Assert
        expect(map['email'], user.email);
        expect(map['displayName'], isNull);
        expect(map['username'], isNull);
        expect(map['bio'], isNull);
        expect(map['photoUrl'], isNull);
        expect(map['followers'], isEmpty);
        expect(map['following'], isEmpty);
        expect(map['fcmTokens'], isEmpty);
      });

      test('should round-trip correctly (fromMap -> toMap -> fromMap)', () {
        // Arrange
        const id = 'user-123';
        final originalMap = {
          'email': 'test@test.com',
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': 'Test bio',
          'photoUrl': 'https://example.com/photo.jpg',
          'followers': ['follower1', 'follower2'],
          'following': ['following1'],
          'fcmTokens': ['token1', 'token2'],
        };

        // Act
        final user = UserModel.fromMap(originalMap, id);
        final map = user.toMap();
        final roundTripUser = UserModel.fromMap(map, id);

        // Assert
        expect(roundTripUser.uid, id);
        expect(roundTripUser.email, user.email);
        expect(roundTripUser.displayName, user.displayName);
        expect(roundTripUser.username, user.username);
        expect(roundTripUser.bio, user.bio);
        expect(roundTripUser.photoUrl, user.photoUrl);
        expect(roundTripUser.followers, user.followers);
        expect(roundTripUser.following, user.following);
        expect(roundTripUser.fcmTokens, user.fcmTokens);
      });
    });

    group('copyWith', () {
      test('should copy UserModel with updated fields', () {
        // Arrange
        final original = UserModel(
          uid: 'user-123',
          email: 'test@test.com',
          displayName: 'Original Name',
          bio: 'Original Bio',
        );

        // Act
        final copied = original.copyWith(
          displayName: 'New Name',
          bio: 'New Bio',
        );

        // Assert
        expect(copied.uid, original.uid);
        expect(copied.email, original.email);
        expect(copied.displayName, 'New Name');
        expect(copied.bio, 'New Bio');
        expect(copied.username, original.username);
        expect(copied.photoUrl, original.photoUrl);
      });

      test('should copy UserModel without changes when no parameters', () {
        // Arrange
        final original = UserModel(
          uid: 'user-123',
          email: 'test@test.com',
          displayName: 'Test User',
          followers: ['follower1'],
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.uid, original.uid);
        expect(copied.email, original.email);
        expect(copied.displayName, original.displayName);
        expect(copied.followers, original.followers);
      });

      test('should update all fields with copyWith', () {
        // Arrange
        final original = UserModel(
          uid: 'user-123',
          email: 'old@test.com',
          displayName: 'Old Name',
          followers: ['old1'],
        );

        // Act
        final copied = original.copyWith(
          uid: 'user-456',
          email: 'new@test.com',
          displayName: 'New Name',
          username: 'newuser',
          bio: 'New Bio',
          photoUrl: 'https://new.com/photo.jpg',
          followers: ['new1', 'new2'],
          following: ['new3'],
          fcmTokens: ['newtoken'],
        );

        // Assert
        expect(copied.uid, 'user-456');
        expect(copied.email, 'new@test.com');
        expect(copied.displayName, 'New Name');
        expect(copied.username, 'newuser');
        expect(copied.bio, 'New Bio');
        expect(copied.photoUrl, 'https://new.com/photo.jpg');
        expect(copied.followers, ['new1', 'new2']);
        expect(copied.following, ['new3']);
        expect(copied.fcmTokens, ['newtoken']);
      });

      test('should preserve original value when null is passed to copyWith', () {
        // Arrange
        final original = UserModel(
          uid: 'user-123',
          email: 'test@test.com',
          displayName: 'Original Name',
          bio: 'Original Bio',
        );

        // Act
        final copied = original.copyWith(
          displayName: null,
          bio: null,
        );

        // Assert - copyWith preserves original value when null is passed
        // This is standard Dart copyWith behavior (null means "don't change")
        expect(copied.displayName, original.displayName);
        expect(copied.bio, original.bio);
      });
    });
  });
}

