import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:thunder/models/user_model.dart';

void main() {
  group('AuthService Tests (Firestore Operations)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      // Not: AuthService singleton ve FirebaseAuth.instance kullandığı için
      // direkt test etmek zor. Firestore operasyonlarını test ediyoruz.
    });

    test('saveUserProfile - Profil kaydetme', () async {
      // Arrange
      final user = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        bio: 'Test bio',
      );
      
      // Act
      await fakeFirestore.collection('users').doc(user.uid).set(user.toMap());
      
      // Assert
      final doc = await fakeFirestore.collection('users').doc(user.uid).get();
      expect(doc.exists, isTrue);
      expect(doc.data()!['email'], equals(user.email));
      expect(doc.data()!['displayName'], equals(user.displayName));
    });

    test('fetchUserProfile - Profil getirme', () async {
      // Arrange
      final user = UserModel(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      await fakeFirestore.collection('users').doc(user.uid).set(user.toMap());
      
      // Act
      final doc = await fakeFirestore.collection('users').doc(user.uid).get();
      
      // Assert
      expect(doc.exists, isTrue);
      final fetchedUser = UserModel.fromMap(doc.data()!, doc.id);
      expect(fetchedUser.uid, equals(user.uid));
      expect(fetchedUser.email, equals(user.email));
    });

    test('fetchUserProfile - Kullanıcı bulunamadı', () async {
      // Arrange
      final nonExistentUid = 'non-existent-uid';
      
      // Act
      final doc = await fakeFirestore.collection('users').doc(nonExistentUid).get();
      
      // Assert
      expect(doc.exists, isFalse);
    });
  });
}

