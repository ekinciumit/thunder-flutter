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
        try {
          final result = await _authRepository!.signIn(email, password);
          
          if (result.isRight) {
            // ✅ Yeni kod başarılı
            signedInUser = result.right;
          } else {
            // ❌ Yeni kod hata verdi, eski koda geç
            final failure = result.left;
            throw Exception(failure.message);
          }
        } catch (e) {
          // Yeni kod exception fırlattı, eski koda geç (fallback)
          // Devam et, eski kodu kullan
        }
      }
      
      // ESKİ KODU KULLAN (Fallback veya yeni kod yoksa)
      if (signedInUser == null) {
        signedInUser = await _authService.signIn(email, password);
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
      final signedUpUser = await _authService.signUp(email, password);
      if (signedUpUser != null) {
        // Firestore'dan tam profil verisini çek
        user = await _authService.fetchUserProfile(signedUpUser.uid) ?? signedUpUser;
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
    await _authService.saveUserProfile(user!);
    needsProfileCompletion = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    if (user == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final profile = await _authService.fetchUserProfile(user!.uid);
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