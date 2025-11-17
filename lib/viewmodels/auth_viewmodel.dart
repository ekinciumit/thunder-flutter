import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/sign_in_usecase.dart';
import '../features/auth/domain/usecases/sign_up_usecase.dart';
import '../features/auth/domain/usecases/sign_out_usecase.dart';
import '../features/auth/domain/usecases/fetch_user_profile_usecase.dart';
import '../features/auth/domain/usecases/save_user_profile_usecase.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  String? error;
  bool needsProfileCompletion = false;

  final IAuthService _authService; // Eski kod (fallback)
  AuthRepository? _authRepository; // Yeni kod (opsiyonel - mutable)
  
  // Use Cases (opsiyonel - fallback mekanizması var)
  SignInUseCase? _signInUseCase;
  SignUpUseCase? _signUpUseCase;
  SignOutUseCase? _signOutUseCase;
  FetchUserProfileUseCase? _fetchUserProfileUseCase;
  SaveUserProfileUseCase? _saveUserProfileUseCase;

  AuthViewModel({
    IAuthService? authService,
    AuthRepository? authRepository, // Yeni kod opsiyonel
  }) : _authService = authService ?? AuthService(),
       _authRepository = authRepository {
    _initializeUseCases();
    _initializeUser();
  }
  
  /// Use Cases'i oluştur (eğer Repository varsa)
  void _initializeUseCases() {
    if (_authRepository != null) {
      _signInUseCase = SignInUseCase(_authRepository!);
      _signUpUseCase = SignUpUseCase(_authRepository!);
      _signOutUseCase = SignOutUseCase(_authRepository!);
      _fetchUserProfileUseCase = FetchUserProfileUseCase(_authRepository!);
      _saveUserProfileUseCase = SaveUserProfileUseCase(_authRepository!);
    } else {
      _signInUseCase = null;
      _signUpUseCase = null;
      _signOutUseCase = null;
      _fetchUserProfileUseCase = null;
      _saveUserProfileUseCase = null;
    }
  }
  
  /// Kullanıcıyı başlat
  void _initializeUser() {
    if (_authRepository != null) {
      user = _authRepository!.getCurrentUser();
    } else {
      user = _authService.getCurrentUser();
    }
  }
  
  /// Repository güncellendiğinde çağrılır (ChangeNotifierProxyProvider'dan)
  void updateRepository(AuthRepository? repository) {
    _authRepository = repository;
    _initializeUseCases();
    _initializeUser();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      UserModel? signedInUser;
      
      // ÖNCE USE CASE'İ DENE (Clean Architecture - Domain Layer)
      if (_signInUseCase != null) {
        print('🔄 Use Case kullanılıyor: signIn (Clean Architecture)');
        try {
          final result = await _signInUseCase!(email, password);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            print('✅ Use Case başarılı: signIn');
            signedInUser = result.right;
          } else {
            // ❌ Use Case hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Use Case hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Use Case exception fırlattı, eski koda geç (fallback)
          print('⚠️ Use Case exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: signIn (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya Use Case yoksa)
      if (signedInUser == null) {
        signedInUser = await _authService.signIn(email, password);
        print('✅ Eski kod başarılı: signIn');
      }
      
      if (signedInUser != null) {
        // Firestore'dan tam profil verisini çek
        UserModel? profile;
        
        // Profil çekmeyi Use Case ile dene
        if (_fetchUserProfileUseCase != null) {
          try {
            final profileResult = await _fetchUserProfileUseCase!(signedInUser.uid);
            if (profileResult.isRight) {
              profile = profileResult.right;
            }
          } catch (e) {
            // Use Case hata verdi, eski koda geç
          }
        }
        
        // Eski kodla profil çek (fallback veya Use Case yoksa)
        if (profile == null) {
          profile = await _authService.fetchUserProfile(signedInUser.uid);
        }
        
        user = profile ?? signedInUser;
        
        // Eğer profil yoksa, profil tamamlama gerekli
        needsProfileCompletion = profile == null;
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
      UserModel? signedUpUser;
      
      // ÖNCE USE CASE'İ DENE (Clean Architecture - Domain Layer)
      if (_signUpUseCase != null) {
        print('🔄 Use Case kullanılıyor: signUp (Clean Architecture)');
        try {
          final result = await _signUpUseCase!(email, password);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            print('✅ Use Case başarılı: signUp');
            signedUpUser = result.right;
          } else {
            // ❌ Use Case hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Use Case hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Use Case exception fırlattı, eski koda geç (fallback)
          print('⚠️ Use Case exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: signUp (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya Use Case yoksa)
      if (signedUpUser == null) {
        signedUpUser = await _authService.signUp(email, password);
        print('✅ Eski kod başarılı: signUp');
      }
      
      if (signedUpUser != null) {
        // Firestore'dan tam profil verisini çek
        UserModel? profile;
        
        // Profil çekmeyi Use Case ile dene
        if (_fetchUserProfileUseCase != null) {
          try {
            final profileResult = await _fetchUserProfileUseCase!(signedUpUser.uid);
            if (profileResult.isRight) {
              profile = profileResult.right;
            }
          } catch (e) {
            // Use Case hata verdi, eski koda geç
          }
        }
        
        // Eski kodla profil çek (fallback veya Use Case yoksa)
        if (profile == null) {
          profile = await _authService.fetchUserProfile(signedUpUser.uid);
        }
        
        user = profile ?? signedUpUser;
        needsProfileCompletion = true;
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
      // ÖNCE USE CASE'İ DENE (Clean Architecture - Domain Layer)
      if (_saveUserProfileUseCase != null) {
        print('🔄 Use Case kullanılıyor: completeProfile (Clean Architecture)');
        try {
          final result = await _saveUserProfileUseCase!(user!);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            print('✅ Use Case başarılı: completeProfile');
            needsProfileCompletion = false;
            notifyListeners();
            return;
          } else {
            // ❌ Use Case hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Use Case hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Use Case exception fırlattı, eski koda geç (fallback)
          print('⚠️ Use Case exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: completeProfile (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya Use Case yoksa)
      await _authService.saveUserProfile(user!);
      print('✅ Eski kod başarılı: completeProfile');
      needsProfileCompletion = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // ÖNCE USE CASE'İ DENE (Clean Architecture - Domain Layer)
      if (_signOutUseCase != null) {
        print('🔄 Use Case kullanılıyor: signOut (Clean Architecture)');
        try {
          final result = await _signOutUseCase!();
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            print('✅ Use Case başarılı: signOut');
            user = null;
            notifyListeners();
            return;
          } else {
            // ❌ Use Case hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Use Case hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Use Case exception fırlattı, eski koda geç (fallback)
          print('⚠️ Use Case exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: signOut (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya Use Case yoksa)
      await _authService.signOut();
      print('✅ Eski kod başarılı: signOut');
      user = null;
      notifyListeners();
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
      UserModel? profile;
      
      // ÖNCE USE CASE'İ DENE (Clean Architecture - Domain Layer)
      if (_fetchUserProfileUseCase != null) {
        print('🔄 Use Case kullanılıyor: loadUserProfile (Clean Architecture)');
        try {
          final result = await _fetchUserProfileUseCase!(user!.uid);
          
          if (result.isRight) {
            // ✅ Use Case başarılı
            print('✅ Use Case başarılı: loadUserProfile');
            profile = result.right;
          } else {
            // ❌ Use Case hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Use Case hata verdi, eski koda geçiliyor: ${failure.message}');
            // Devam et, eski kodu kullan
          }
        } catch (e) {
          // Use Case exception fırlattı, eski koda geç (fallback)
          print('⚠️ Use Case exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: loadUserProfile (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya Use Case yoksa)
      if (profile == null) {
        profile = await _authService.fetchUserProfile(user!.uid);
        print('✅ Eski kod başarılı: loadUserProfile');
      }
      
      if (profile != null) {
        user = profile;
      }
    } catch (e) {
      error = e.toString();
    }
    
    isLoading = false;
    notifyListeners();
  }
} 