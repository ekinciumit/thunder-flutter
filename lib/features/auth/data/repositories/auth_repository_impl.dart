import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/data/mappers/user_mapper.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication Repository Implementation
/// 
/// Bu sınıf Clean Architecture'ın data katmanında yer alır ve:
/// - Domain repository interface'ini implement eder
/// - Remote ve local data source'ları kullanır
/// - Exception'ları Failure'lara çevirir
/// 
/// ŞU AN: Bu implementation sadece ekleniyor, mevcut kod çalışmaya devam ediyor
/// İleride bu repository'yi kullanacağız

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
    try {
      // Önce remote'dan giriş yap (DTO alır)
      final userModel = await _remoteDataSource.signIn(email, password);
      
      // Başarılı olursa cache'e kaydet (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(userModel);
      } on CacheException catch (e) {
        // Cache hatası kritik değil, kullanıcı zaten giriş yaptı
        // Sadece log'a yaz, devam et
        if (kDebugMode) {
          debugPrint('⚠️ Cache hatası (kritik değil): ${e.message}');
        }
      }
      
      // DTO -> Entity dönüşümü
      return Either.right(UserMapper.toEntity(userModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(String email, String password) async {
    try {
      // Önce remote'dan kayıt ol (DTO alır)
      final userModel = await _remoteDataSource.signUp(email, password);
      
      // ✅ Yeni kullanıcı profili oluştur ve Firestore'a kaydet
      // Minimal UserModel'i tam profil olarak kaydet (default değerlerle)
      final fullUserModel = UserModel(
        uid: userModel.uid,
        email: userModel.email,
        displayName: null, // Profil tamamlama sayfasında doldurulacak
        username: null,
        bio: null,
        photoUrl: null,
        followers: const [],
        following: const [],
        fcmTokens: const [],
        pendingFollowRequests: const [],
        sentFollowRequests: const [],
        isPrivate: false,
        showLocation: true,
        showOnlineStatus: true,
        blockedUsers: const [],
      );
      
      // ✅ Firestore'a kaydet (profil tamamlama sayfasında güncellenecek)
      await _remoteDataSource.saveUserProfile(fullUserModel);
      
      // Başarılı olursa cache'e kaydet (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(fullUserModel);
      } on CacheException catch (e) {
        // Cache hatası kritik değil, kullanıcı zaten kayıt oldu
        // Sadece log'a yaz, devam et
        if (kDebugMode) {
          debugPrint('⚠️ Cache hatası (kritik değil): ${e.message}');
        }
      }
      
      // DTO -> Entity dönüşümü
      return Either.right(UserMapper.toEntity(fullUserModel));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();
      // Çıkış yapınca cache'i temizle
      await _localDataSource.clearCache();
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Çıkış yapılırken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserProfile(UserEntity user) async {
    try {
      // Entity -> DTO dönüşümü
      final userModel = UserMapper.toModel(user);
      await _remoteDataSource.saveUserProfile(userModel);
      // Profil kaydedilince cache'i güncelle (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(userModel);
      } on CacheException catch (e) {
        // Cache hatası kritik değil, profil zaten kaydedildi
        // Sadece log'a yaz, devam et
        if (kDebugMode) {
          debugPrint('⚠️ Cache hatası (kritik değil): ${e.message}');
        }
      }
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Profil kaydedilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> fetchUserProfile(String uid) async {
    try {
      // Önce cache'den kontrol et
      final cachedUserModel = await _localDataSource.getCachedUser();
      if (cachedUserModel != null && cachedUserModel.uid == uid) {
        // Cache'de varsa direkt döndür (offline support) - DTO -> Entity
        return Either.right(UserMapper.toEntity(cachedUserModel));
      }
      
      // Cache'de yoksa remote'dan getir
      final userModel = await _remoteDataSource.fetchUserProfile(uid);
      
      // Eğer remote'dan geldiyse cache'e kaydet
      if (userModel != null) {
        await _localDataSource.cacheUser(userModel);
        // DTO -> Entity dönüşümü
        return Either.right(UserMapper.toEntity(userModel));
      }
      
      return Either.right(null);
    } on ServerException catch (e) {
      // Remote hata verirse cache'den döndürmeyi dene
      final cachedUserModel = await _localDataSource.getCachedUser();
      if (cachedUserModel != null && cachedUserModel.uid == uid) {
        // Cache'de varsa onu döndür (offline support) - DTO -> Entity
        return Either.right(UserMapper.toEntity(cachedUserModel));
      }
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Profil getirilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserToken(String token) async {
    try {
      await _remoteDataSource.saveUserToken(token);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Token kaydedilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  UserEntity? getCurrentUser() {
    try {
      // Önce cache'den kontrol et
      // Not: getCachedUser async, bu yüzden sadece remote'dan alıyoruz
      // İleride cache'i sync yapabiliriz
      final userModel = _remoteDataSource.getCurrentUser();
      return userModel != null ? UserMapper.toEntity(userModel) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AUTH_REPO] getCachedToken hatası: $e');
      }
      return null;
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(String photoFilePath, String userId) async {
    try {
      final file = File(photoFilePath);
      final url = await _remoteDataSource.uploadProfilePhoto(file, userId);
      return Either.right(url);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Profil fotoğrafı yüklenirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Stream<List<UserEntity>> getAllUsersStream() {
    try {
      // DTO stream'i -> Entity stream'e çevir
      return _remoteDataSource.getAllUsersStream().map((userModels) {
        return UserMapper.toEntityList(userModels);
      });
    } catch (e) {
      // Stream'ler için hata durumunda boş stream döndür
      return Stream.value(<UserEntity>[]);
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Şifre sıfırlama emaili gönderilirken bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount({required String password}) async {
    try {
      await _remoteDataSource.deleteAccount(password: password);
      await _localDataSource.clearCache();
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Hesap silinirken bir hata oluştu: ${e.toString()}'));
    }
  }
}

/// Factory function for creating AuthRepositoryImpl
/// 
/// Bu fonksiyon Service Locator'da kullanılabilir
Future<AuthRepository> createAuthRepository() async {
  if (kDebugMode) {
    debugPrint('🏗️ [ARCH] createAuthRepository: Clean Architecture Repository oluşturuluyor...');
  }
  final prefs = await SharedPreferences.getInstance();
  
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    localDataSource: AuthLocalDataSourceImpl(prefs: prefs),
  );
}

