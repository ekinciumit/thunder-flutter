import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../core/errors/failures.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  String? error;
  bool needsProfileCompletion = false;

  final IAuthService _authService; // Eski kod (fallback)
  final AuthRepository? _authRepository; // Yeni kod (opsiyonel)

  AuthViewModel({
    IAuthService? authService,
    AuthRepository? authRepository, // Yeni kod opsiyonel
  }) : _authService = authService ?? AuthService(),
       _authRepository = authRepository {
    // Önce yeni koddan deneyelim, yoksa eski koddan
    if (_authRepository != null) {
      user = _authRepository!.getCurrentUser();
    } else {
      user = _authService.getCurrentUser();
    }
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      UserModel? signedInUser;
      
      // ÖNCE YENİ KODU DENE (Clean Architecture)
      if (_authRepository != null) {
        print('🔄 Yeni kod kullanılıyor (Clean Architecture)');
        try {
          final result = await _authRepository!.signIn(email, password);
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            print('✅ Yeni kod başarılı: signIn');
            signedInUser = result.right;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Yeni kod hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          print('⚠️ Yeni kod exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
      if (signedInUser == null) {
        signedInUser = await _authService.signIn(email, password);
        print('✅ Eski kod başarılı: signIn');
      }
      
      if (signedInUser != null) {
        // Firestore'dan tam profil verisini çek
        UserModel? profile;
        
        // Profil çekmeyi de yeni koddan deneyelim
        if (_authRepository != null) {
          try {
            final profileResult = await _authRepository!.fetchUserProfile(signedInUser.uid);
            if (profileResult.isRight) {
              profile = profileResult.right;
            }
          } catch (e) {
            // Yeni kod hata verdi, eski koda geç
          }
        }
        
        // Eski kodla profil çek (fallback veya yeni kod yoksa)
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
      
      // ÖNCE YENİ KODU DENE (Clean Architecture)
      if (_authRepository != null) {
        print('🔄 Yeni kod kullanılıyor: signUp (Clean Architecture)');
        try {
          final result = await _authRepository!.signUp(email, password);
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            print('✅ Yeni kod başarılı: signUp');
            signedUpUser = result.right;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Yeni kod hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          print('⚠️ Yeni kod exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: signUp (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
      if (signedUpUser == null) {
        signedUpUser = await _authService.signUp(email, password);
        print('✅ Eski kod başarılı: signUp');
      }
      
      if (signedUpUser != null) {
        // Firestore'dan tam profil verisini çek
        UserModel? profile;
        
        // Profil çekmeyi de yeni koddan deneyelim
        if (_authRepository != null) {
          try {
            final profileResult = await _authRepository!.fetchUserProfile(signedUpUser.uid);
            if (profileResult.isRight) {
              profile = profileResult.right;
            }
          } catch (e) {
            // Yeni kod hata verdi, eski koda geç
          }
        }
        
        // Eski kodla profil çek (fallback veya yeni kod yoksa)
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
      // ÖNCE YENİ KODU DENE (Clean Architecture)
      if (_authRepository != null) {
        print('🔄 Yeni kod kullanılıyor: completeProfile (Clean Architecture)');
        try {
          final result = await _authRepository!.saveUserProfile(user!);
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            print('✅ Yeni kod başarılı: completeProfile');
            needsProfileCompletion = false;
            notifyListeners();
            return;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Yeni kod hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          print('⚠️ Yeni kod exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: completeProfile (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
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
      // ÖNCE YENİ KODU DENE (Clean Architecture)
      if (_authRepository != null) {
        print('🔄 Yeni kod kullanılıyor: signOut (Clean Architecture)');
        try {
          final result = await _authRepository!.signOut();
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            print('✅ Yeni kod başarılı: signOut');
            user = null;
            notifyListeners();
            return;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Yeni kod hata verdi, eski koda geçiliyor: ${failure.message}');
            throw Exception(failure.message);
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          print('⚠️ Yeni kod exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: signOut (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
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
      
      // ÖNCE YENİ KODU DENE (Clean Architecture)
      if (_authRepository != null) {
        print('🔄 Yeni kod kullanılıyor: loadUserProfile (Clean Architecture)');
        try {
          final result = await _authRepository!.fetchUserProfile(user!.uid);
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            print('✅ Yeni kod başarılı: loadUserProfile');
            profile = result.right;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            print('⚠️ Yeni kod hata verdi, eski koda geçiliyor: ${failure.message}');
            // Devam et, eski kodu kullan
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          print('⚠️ Yeni kod exception, eski koda geçiliyor: $e');
          // Devam et, eski kodu kullan
        }
      } else {
        print('📦 Eski kod kullanılıyor: loadUserProfile (fallback)');
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
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