import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../user/data/models/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/image_compressor.dart';

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
  
  /// Profil fotoğrafını yükler ve download URL'ini döndürür
  Future<String> uploadProfilePhoto(File photoFile, String userId);
  
  /// Tüm kullanıcıları stream olarak getir
  Stream<List<UserModel>> getAllUsersStream();

  /// Şifre sıfırlama email'i gönder
  Future<void> sendPasswordResetEmail(String email);
}

/// Firebase implementation of AuthRemoteDataSource
/// 
/// Bu sınıf mevcut AuthService'in remote işlemlerini yapar.
/// Mevcut kodun mantığını koruyarak yazıldı.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

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
      // Ama hatayı logla
      if (kDebugMode) {
        debugPrint('❌ [AUTH_DS] fetchUserProfile hatası: $e');
      }
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
      if (kDebugMode) {
        debugPrint('❌ [AUTH_DS] getCachedToken hatası: $e');
      }
      return null;
    }
  }

  @override
  Future<String> uploadProfilePhoto(File photoFile, String userId) async {
    try {
      if (!await photoFile.exists()) {
        throw ServerException('Fotoğraf dosyası bulunamadı');
      }

      // Cost Optimization: Compress image before upload (70-80% storage savings)
      final compressedFile = await ImageCompressor.compressProfilePhoto(photoFile);

      // Güvenlik: UID bazlı path yapısı - sadece kendi klasörüne yazabilir
      final fileId = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('profile_photos').child(userId).child(fileId);

      final uploadTask = storageRef.putFile(compressedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Clean up temporary compressed file
      try {
        if (compressedFile.path != photoFile.path) {
          await compressedFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
      
      return downloadUrl;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Profil fotoğrafı yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Stream<List<UserModel>> getAllUsersStream() {
    try {
      return _firestore
          .collection('users')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw ServerException('Kullanıcılar getirilirken hata oluştu: ${e.toString()}');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(ErrorMapper.mapFirebaseAuthException(e));
    } catch (e) {
      throw ServerException('Şifre sıfırlama emaili gönderilirken hata oluştu: ${e.toString()}');
    }
  }
}

