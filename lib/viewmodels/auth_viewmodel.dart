import 'package:flutter/material.dart';
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
    
    print('🏗️ [ARCH] SignIn: Clean Architecture kullanılıyor (Use Case)');
    print('🔄 [TEST] SignIn başlatıldı: $email');
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signInUseCase(email, password);
      
      print('🔄 [TEST] SignInUseCase sonucu: isRight=${result.isRight}');
      
      if (result.isRight) {
        final signedInUser = result.right;
        print('✅ [TEST] SignInUseCase başarılı, user: ${signedInUser.uid}');
        
        // Firestore'dan tam profil verisini çek
        print('🔄 [TEST] Profil çekiliyor: ${signedInUser.uid}');
        final profileResult = await _fetchUserProfileUseCase(signedInUser.uid);
        print('🔄 [TEST] FetchUserProfile sonucu: isRight=${profileResult.isRight}');
        
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = profileResult.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        
        user = profile ?? signedInUser;
        
        // Eğer profil yoksa, profil tamamlama gerekli
        needsProfileCompletion = profile == null;
        print('✅ [TEST] SignIn başarılı, user=${user?.uid}, needsProfileCompletion=$needsProfileCompletion');
      } else {
        // Failure durumu
        final failure = result.left;
        error = failure.message;
        print('❌ [TEST] SignInUseCase başarısız: ${failure.message}');
      }
    } catch (e) {
      error = e.toString();
      print('❌ [TEST] SignIn exception: $e');
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    print('🏗️ [ARCH] SignUp: Clean Architecture kullanılıyor (Use Case)');
    
    try {
      print('🔄 [TEST] SignUp başlatıldı: $email');
      // Clean Architecture: Use Case kullan
      final result = await _signUpUseCase(email, password);
      
      print('🔄 [TEST] SignUpUseCase sonucu: isRight=${result.isRight}');
      
      if (result.isRight) {
        final signedUpUser = result.right;
        print('✅ [TEST] SignUpUseCase başarılı, user: ${signedUpUser.uid}');
        
        // Firestore'dan tam profil verisini çek
        print('🔄 [TEST] Profil çekiliyor: ${signedUpUser.uid}');
        final profileResult = await _fetchUserProfileUseCase(signedUpUser.uid);
        print('🔄 [TEST] FetchUserProfile sonucu: isRight=${profileResult.isRight}');
        
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = profileResult.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        
        user = profile ?? signedUpUser;
        needsProfileCompletion = true; // Yeni kullanıcı için profil tamamlama gerekli
        justSignedUp = true; // SignUp başarılı flag'i (mesaj göstermek için)
        print('✅ [TEST] SignUp başarılı, justSignedUp=true set edildi, user=${user?.uid}');
      } else {
        // Failure durumu
        final failure = result.left;
        error = failure.message;
        print('❌ [TEST] SignUpUseCase başarısız: ${failure.message}');
      }
    } catch (e) {
      error = e.toString();
      print('❌ [TEST] SignUp exception: $e');
    }
    
    isLoading = false;
    notifyListeners();
    print('🔄 [TEST] SignUp tamamlandı, notifyListeners çağrıldı');
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
    
    print('🏗️ [ARCH] CompleteProfile: Clean Architecture kullanılıyor (Use Case)');
    print('🔄 [TEST] CompleteProfile başlatıldı: displayName=$displayName');
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _saveUserProfileUseCase(user!);
      
      print('🔄 [TEST] SaveUserProfileUseCase sonucu: isRight=${result.isRight}');
      
      if (result.isRight) {
        // ✅ Use Case başarılı
        needsProfileCompletion = false;
        print('✅ [TEST] CompleteProfile başarılı, needsProfileCompletion=false');
        notifyListeners();
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
        print('❌ [TEST] SaveUserProfileUseCase başarısız: ${failure.message}');
        notifyListeners();
        throw Exception(failure.message);
      }
    } catch (e) {
      error = e.toString();
      print('❌ [TEST] CompleteProfile exception: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    print('🏗️ [ARCH] SignOut: Clean Architecture kullanılıyor (Use Case)');
    print('🔄 [TEST] SignOut başlatıldı');
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signOutUseCase();
      
      print('🔄 [TEST] SignOutUseCase sonucu: isRight=${result.isRight}');
      
      if (result.isRight) {
        // ✅ Use Case başarılı
        user = null;
        print('✅ [TEST] SignOut başarılı, user=null');
        notifyListeners();
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
        print('❌ [TEST] SignOutUseCase başarısız: ${failure.message}');
        notifyListeners();
        throw Exception(failure.message);
      }
    } catch (e) {
      // Hata durumunda da user'ı temizle
      user = null;
      print('❌ [TEST] SignOut exception: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadUserProfile() async {
    if (user == null) return;
    isLoading = true;
    notifyListeners();
    
    print('🏗️ [ARCH] LoadUserProfile: Clean Architecture kullanılıyor (Use Case)');
    
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
      } else {
        // ❌ Use Case hata verdi (profil bulunamadı, normal olabilir)
        final failure = result.left;
        print('⚠️ Profil yüklenemedi: ${failure.message}');
        // Hata mesajını gösterme, sadece log'a yaz
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }
} 