import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:thunder/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:thunder/models/user_model.dart';
import 'package:thunder/core/errors/exceptions.dart';

import 'auth_remote_data_source_test.mocks.dart';

/// Mock classes için annotation
/// 
/// Bu annotation mockito'ya mock sınıfları oluşturmasını söyler
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  FirebaseFirestore,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late MockDocumentReference mockDocRef;
  late MockDocumentSnapshot mockDocSnapshot;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCredential = MockUserCredential();
    mockUser = MockUser();
    mockDocRef = MockDocumentReference();
    mockDocSnapshot = MockDocumentSnapshot();

    dataSource = AuthRemoteDataSourceImpl(
      auth: mockAuth,
      firestore: mockFirestore,
    );
  });

  group('signIn', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUid = 'test-uid-123';

    test('should return UserModel when sign in is successful', () async {
      // Arrange
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(testEmail);
      when(mockCredential.user).thenReturn(mockUser);
      when(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockCredential);

      // Act
      final result = await dataSource.signIn(testEmail, testPassword);

      // Assert
      expect(result, isA<UserModel>());
      expect(result.uid, testUid);
      expect(result.email, testEmail);
      verify(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    test('should throw ServerException when FirebaseAuthException occurs', () async {
      // Arrange
      when(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      ));

      // Act & Assert
      expect(
        () => dataSource.signIn(testEmail, testPassword),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw ServerException when user is null', () async {
      // Arrange
      when(mockCredential.user).thenReturn(null);
      when(mockAuth.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockCredential);

      // Act & Assert
      expect(
        () => dataSource.signIn(testEmail, testPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('signUp', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUid = 'test-uid-123';

    test('should return UserModel when sign up is successful', () async {
      // Arrange
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(testEmail);
      when(mockCredential.user).thenReturn(mockUser);
      when(mockAuth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenAnswer((_) async => mockCredential);

      // Act
      final result = await dataSource.signUp(testEmail, testPassword);

      // Assert
      expect(result, isA<UserModel>());
      expect(result.uid, testUid);
      expect(result.email, testEmail);
      verify(mockAuth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    test('should throw ServerException when FirebaseAuthException occurs', () async {
      // Arrange
      when(mockAuth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      )).thenThrow(FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email already in use',
      ));

      // Act & Assert
      expect(
        () => dataSource.signUp(testEmail, testPassword),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('signOut', () {
    test('should call signOut successfully', () async {
      // Arrange
      when(mockAuth.signOut()).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.signOut();

      // Assert
      verify(mockAuth.signOut()).called(1);
    });

    test('should throw ServerException when signOut fails', () async {
      // Arrange
      when(mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

      // Act & Assert
      expect(
        () => dataSource.signOut(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getCurrentUser', () {
    const testUid = 'test-uid-123';
    const testEmail = 'test@example.com';

    test('should return UserModel when user is logged in', () {
      // Arrange
      when(mockUser.uid).thenReturn(testUid);
      when(mockUser.email).thenReturn(testEmail);
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Act
      final result = dataSource.getCurrentUser();

      // Assert
      expect(result, isA<UserModel>());
      expect(result?.uid, testUid);
      expect(result?.email, testEmail);
    });

    test('should return null when user is not logged in', () {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final result = dataSource.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });
}

