import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DemoService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Demo kullanıcı oluştur
  static Future<void> createDemoUser() async {
    try {
      // Demo kullanıcı ile giriş yap
      final credential = await _auth.signInWithEmailAndPassword(
        email: 'demo12@gmail.com',
        password: 'demo123456'
      );

      if (credential.user != null) {
        // Demo kullanıcı profilini oluştur
        final demoUser = UserModel(
          uid: credential.user!.uid,
          email: 'demo12@gmail.com',
          displayName: 'Demo Kullanıcı',
          bio: 'Bu bir demo hesaptır',
        );

        // Firestore'a kaydet
        await _firestore.collection('users').doc(credential.user!.uid).set(
          demoUser.toMap(),
          SetOptions(merge: true)
        );

        // print('Demo kullanıcı oluşturuldu: ${credential.user!.uid}');
      }
    } catch (e) {
      // print('Demo kullanıcı oluşturma hatası: $e');
    }
  }

  // Demo kullanıcı ile giriş yap
  static Future<bool> signInDemo() async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: 'demo12@gmail.com',
        password: 'demo123456'
      );
      return credential.user != null;
    } catch (e) {
      // print('Demo giriş hatası: $e');
      return false;
    }
  }
}
