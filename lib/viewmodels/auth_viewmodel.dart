import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? user;
  bool isLoading = false;
  String? error;
  bool needsProfileCompletion = false;

  final IAuthService _authService;

  AuthViewModel({IAuthService? authService}) : _authService = authService ?? AuthService() {
    user = _authService.getCurrentUser();
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final signedInUser = await _authService.signIn(email, password);
      if (signedInUser != null) {
        // Firestore'dan tam profil verisini çek
        final profile = await _authService.fetchUserProfile(signedInUser.uid);
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