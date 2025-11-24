import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/error_mapper.dart';

/// Remote data source interface for authentication
/// 
/// Bu interface SOLID prensiplerinden Interface Segregation Principle'a uyar:
/// - Sadece remote (Firebase) işlemlerinden sorumlu
/// - Local işlemler ayrı interface'de
/// 
/// ŞU AN: Bu interface sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu interface'i implement edeceğiz

abstract class AuthRemoteDataSource {
  /// Email/password ile giriş yap
  /// 
  /// Throws: ServerException if authentication fails
  Future<UserModel> signIn(String email, String password);
  
  /// Email/password ile kayıt ol
  /// 
  /// Throws: ServerException if registration fails
  Future<UserModel> signUp(String email, String password);
  
  /// Çıkış yap
  Future<void> signOut();
  
  /// Kullanıcı profilini Firestore'a kaydet
  /// 
  /// Throws: ServerException if save fails
  Future<void> saveUserProfile(UserModel user);
  
  /// Kullanıcı profilini Firestore'dan getir
  /// 
  /// Returns: UserModel if found, null otherwise
  /// Throws: ServerException if fetch fails
  Future<UserModel?> fetchUserProfile(String uid);
  
  /// FCM token'ını kullanıcıya kaydet
  /// 
  /// Throws: ServerException if save fails
  Future<void> saveUserToken(String token);
  
  /// Mevcut kullanıcıyı getir
  /// 
  /// Returns: UserModel if logged in, null otherwise
  UserModel? getCurrentUser();
}

/// Firebase implementation of AuthRemoteDataSource
/// 
/// Bu sınıf mevcut AuthService'in remote işlemlerini yapar.
/// Mevcut kodun mantığını koruyarak yazıldı.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return UserModel(uid: user.uid, email: user.email ?? '');
      }
      throw ServerException('Giriş başarısız. Kullanıcı bilgisi alınamadı.');
    } on FirebaseAuthException catch (e) {
      // Mevcut kodun kullandığı ErrorMapper'ı kullan
      throw ServerException(ErrorMapper.mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Giriş yapılırken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        return UserModel(uid: user.uid, email: user.email ?? '');
      }
      throw ServerException('Kayıt başarısız. Kullanıcı bilgisi alınamadı.');
    } on FirebaseAuthException catch (e) {
      // Mevcut kodun kullandığı ErrorMapper'ı kullan
      throw ServerException(ErrorMapper.mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Kayıt olurken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw ServerException('Çıkış yapılırken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Profil kaydedilirken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      // Mevcut kodda null döndürülüyor, aynı mantığı koruyoruz
      // Ama exception da fırlatabiliriz, şimdilik null döndürelim
      return null;
    }
  }

  @override
  Future<void> saveUserToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw ServerException('Kullanıcı giriş yapmamış');
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
    } catch (e) {
      throw ServerException('Token kaydedilirken bir hata oluştu: ${e.toString()}');
    }
  }

  @override
  UserModel? getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return UserModel(uid: user.uid, email: user.email ?? '');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

