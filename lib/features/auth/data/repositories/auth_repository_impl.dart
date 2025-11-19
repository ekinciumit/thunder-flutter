import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
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
  Future<Either<Failure, UserModel>> signIn(String email, String password) async {
    try {
      // Önce remote'dan giriş yap
      final user = await _remoteDataSource.signIn(email, password);
      
      // Başarılı olursa cache'e kaydet (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(user);
      } on CacheException catch (e) {
        // Cache hatası kritik değil, kullanıcı zaten giriş yaptı
        // Sadece log'a yaz, devam et
        if (kDebugMode) {
          debugPrint('⚠️ Cache hatası (kritik değil): ${e.message}');
        }
      }
      
      return Either.right(user);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Beklenmeyen bir hata oluştu: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserModel>> signUp(String email, String password) async {
    try {
      // Önce remote'dan kayıt ol
      final user = await _remoteDataSource.signUp(email, password);
      
      // Başarılı olursa cache'e kaydet (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(user);
      } on CacheException catch (e) {
        // Cache hatası kritik değil, kullanıcı zaten kayıt oldu
        // Sadece log'a yaz, devam et
        if (kDebugMode) {
          debugPrint('⚠️ Cache hatası (kritik değil): ${e.message}');
        }
      }
      
      return Either.right(user);
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
  Future<Either<Failure, void>> saveUserProfile(UserModel user) async {
    try {
      await _remoteDataSource.saveUserProfile(user);
      // Profil kaydedilince cache'i güncelle (cache hatası kritik değil)
      try {
        await _localDataSource.cacheUser(user);
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
  Future<Either<Failure, UserModel?>> fetchUserProfile(String uid) async {
    try {
      // Önce cache'den kontrol et
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null && cachedUser.uid == uid) {
        // Cache'de varsa direkt döndür (offline support)
        return Either.right(cachedUser);
      }
      
      // Cache'de yoksa remote'dan getir
      final user = await _remoteDataSource.fetchUserProfile(uid);
      
      // Eğer remote'dan geldiyse cache'e kaydet
      if (user != null) {
        await _localDataSource.cacheUser(user);
      }
      
      return Either.right(user);
    } on ServerException catch (e) {
      // Remote hata verirse cache'den döndürmeyi dene
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null && cachedUser.uid == uid) {
        // Cache'de varsa onu döndür (offline support)
        return Either.right(cachedUser);
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
  UserModel? getCurrentUser() {
    try {
      // Önce cache'den kontrol et
      // Not: getCachedUser async, bu yüzden sadece remote'dan alıyoruz
      // İleride cache'i sync yapabiliriz
      return _remoteDataSource.getCurrentUser();
    } catch (e) {
      return null;
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

