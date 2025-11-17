import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/sign_in_usecase.dart';
import '../features/auth/domain/usecases/sign_up_usecase.dart';
import '../features/auth/domain/usecases/sign_out_usecase.dart';
import '../features/auth/domain/usecases/fetch_user_profile_usecase.dart';
import '../features/auth/domain/usecases/save_user_profile_usecase.dart';

/// AuthViewModel - Clean Architecture Implementation
/// 
/// Faz 4: Fallback mekanizması kaldırıldı, sadece Clean Architecture kullanılıyor.
/// Repository her zaman gereklidir ve Use Cases üzerinden işlemler yapılır.
class AuthViewModel extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  String? error;
  bool needsProfileCompletion = false;
  bool justSignedUp = false; // SignUp başarılı mesajı için flag

  final AuthRepository _authRepository;
  
  // Use Cases - Clean Architecture Domain Layer
  late final SignInUseCase _signInUseCase;
  late final SignUpUseCase _signUpUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final FetchUserProfileUseCase _fetchUserProfileUseCase;
  late final SaveUserProfileUseCase _saveUserProfileUseCase;

  AuthViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    _initializeUseCases();
    _initializeUser();
  }
  
  /// Use Cases'i oluştur
  void _initializeUseCases() {
    _signInUseCase = SignInUseCase(_authRepository);
    _signUpUseCase = SignUpUseCase(_authRepository);
    _signOutUseCase = SignOutUseCase(_authRepository);
    _fetchUserProfileUseCase = FetchUserProfileUseCase(_authRepository);
    _saveUserProfileUseCase = SaveUserProfileUseCase(_authRepository);
  }
  
  /// Kullanıcıyı başlat
  void _initializeUser() {
    user = _authRepository.getCurrentUser();
  }
  
  /// Repository güncellendiğinde çağrılır (ChangeNotifierProxyProvider'dan)
  /// Not: Faz 4'te Repository her zaman mevcut olduğu için bu metod artık kullanılmıyor
  /// ama geriye dönük uyumluluk için bırakıldı
  void updateRepository(AuthRepository? repository) {
    if (repository != null) {
      // Repository değişirse Use Cases'i yeniden oluştur
      // Not: Normalde bu durum oluşmamalı, ama güvenlik için bırakıldı
    }
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signInUseCase(email, password);
          
          if (result.isRight) {
        final signedInUser = result.right;
        
        // Firestore'dan tam profil verisini çek
        final profileResult = await _fetchUserProfileUseCase(signedInUser.uid);
        
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = profileResult.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        
        user = profile ?? signedInUser;
        
        // Eğer profil yoksa, profil tamamlama gerekli
        needsProfileCompletion = profile == null;
      } else {
        // Failure durumu
        final failure = result.left;
        error = failure.message;
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signUpUseCase(email, password);
          
          if (result.isRight) {
        final signedUpUser = result.right;
        
        // Firestore'dan tam profil verisini çek
        final profileResult = await _fetchUserProfileUseCase(signedUpUser.uid);
        
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = profileResult.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        
        user = profile ?? signedUpUser;
        needsProfileCompletion = true; // Yeni kullanıcı için profil tamamlama gerekli
        justSignedUp = true; // SignUp başarılı flag'i (mesaj göstermek için)
      } else {
        // Failure durumu
        final failure = result.left;
        error = failure.message;
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> completeProfile({required String displayName, String? bio, String? photoUrl}) async {
    if (user == null) return;
    
    user = UserModel(
      uid: user!.uid,
      email: user!.email,
      displayName: displayName,
      username: user!.username,
      bio: bio,
      photoUrl: photoUrl,
    );
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _saveUserProfileUseCase(user!);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            needsProfileCompletion = false;
            notifyListeners();
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
        notifyListeners();
        throw Exception(failure.message);
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signOutUseCase();
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            user = null;
            notifyListeners();
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
      notifyListeners();
        throw Exception(failure.message);
      }
    } catch (e) {
      // Hata durumunda da user'ı temizle
      user = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadUserProfile() async {
    if (user == null) return;
    isLoading = true;
    notifyListeners();
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _fetchUserProfileUseCase(user!.uid);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = result.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        if (profile != null) {
          user = profile;
        }
      }
      // Hata durumunda sessizce devam et (profil bulunamadı, normal olabilir)
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }

  /// Başka bir kullanıcının profilini getir
  /// 
  /// Bu metod view'lerde başka kullanıcıların profilini görmek için kullanılır.
  /// Clean Architecture: Use Case kullanır.
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final result = await _fetchUserProfileUseCase(uid);
      return result.fold(
        (failure) => null, // Hata durumunda null döndür
        (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
      );
    } catch (e) {
      return null;
    }
  }

  /// FCM token'ını kaydet
  /// 
  /// Bu metod notification service tarafından kullanılır.
  /// Clean Architecture: Repository kullanır (basit işlem için Use Case yok).
  Future<void> saveUserToken(String token) async {
    try {
      final result = await _authRepository.saveUserToken(token);
      result.fold(
        (failure) {
          // Hata durumunda sessizce devam et (kritik değil)
          if (kDebugMode) {
            debugPrint('⚠️ Token kaydedilemedi: ${failure.message}');
          }
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      // Hata durumunda sessizce devam et (kritik değil)
      if (kDebugMode) {
        debugPrint('⚠️ Token kaydedilemedi: $e');
      }
    }
  }
} 