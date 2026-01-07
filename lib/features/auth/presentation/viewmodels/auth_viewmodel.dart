import 'package:flutter/foundation.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/fetch_user_profile_usecase.dart';
import '../../domain/usecases/save_user_profile_usecase.dart';

/// AuthViewModel - Clean Architecture Implementation
/// 
/// Presentation Layer - State Management
/// Bu ViewModel Clean Architecture'ın presentation katmanında yer alır.
class AuthViewModel extends ChangeNotifier {
  UserEntity? user;
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
    
    user = UserEntity(
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
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Clean Architecture: Use Case kullan
      final result = await _signOutUseCase();
          
      if (result.isRight) {
        // ✅ Use Case başarılı
        user = null;
        needsProfileCompletion = false;
        justSignedUp = false;
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
        throw Exception(failure.message);
      }
    } catch (e) {
      // Hata durumunda da user'ı temizle
      user = null;
      needsProfileCompletion = false;
      justSignedUp = false;
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
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

  /// Kullanıcı profilini yeniden yükle (state senkronizasyonu için)
  /// 
  /// Bu metod takip işlemleri, profil güncellemeleri vb. sonrası
  /// local state'i Firebase ile senkronize etmek için kullanılır.
  /// Loading göstergesi olmadan sessizce günceller.
  Future<void> refreshUserProfile() async {
    if (user == null) return;
    
    try {
      final result = await _fetchUserProfileUseCase(user!.uid);
      
      final profile = result.fold(
        (failure) => null,
        (user) => user,
      );
      
      if (profile != null) {
        user = profile;
        notifyListeners();
      }
    } catch (e) {
      // Sessizce devam et - kritik değil
    }
  }

  /// Başka bir kullanıcının profilini getir
  /// 
  /// Bu metod view'lerde başka kullanıcıların profilini görmek için kullanılır.
  /// Clean Architecture: Use Case kullanır.
  Future<UserEntity?> fetchUserProfile(String uid) async {
    try {
      final result = await _fetchUserProfileUseCase(uid);
      return result.fold(
        (failure) => null, // Hata durumunda null döndür
        (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [AUTH_VM] fetchUserProfile hatası: $e');
      }
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
        },
        (_) {
          // Başarılı
        },
      );
    } catch (e) {
      // Hata durumunda sessizce devam et (kritik değil)
    }
  }

  /// Gizlilik ayarlarını yerel olarak güncelle
  /// 
  /// Bu metod settings sayfasından çağrılır.
  /// Firebase güncellemesi UserService tarafından yapılır, bu sadece yerel state'i günceller.
  void updateUserPrivacy({
    bool? isPrivate,
    bool? showLocation,
    bool? showOnlineStatus,
  }) {
    if (user == null) return;
    
    user = user!.copyWith(
      isPrivate: isPrivate ?? user!.isPrivate,
      showLocation: showLocation ?? user!.showLocation,
      showOnlineStatus: showOnlineStatus ?? user!.showOnlineStatus,
    );
    notifyListeners();
  }

  /// Tüm kullanıcıları stream olarak getir
  Stream<List<UserEntity>> getAllUsersStream() {
    return _authRepository.getAllUsersStream();
  }

  /// Şifre sıfırlama email'i gönder
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _authRepository.sendPasswordResetEmail(email);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return false;
        },
        (_) {
          isLoading = false;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Profil fotoğrafını yükle ve URL'ini döndür
  Future<String?> uploadProfilePhoto(String photoFilePath) async {
    if (user == null) return null;
    
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final result = await _authRepository.uploadProfilePhoto(photoFilePath, user!.uid);
      return result.fold(
        (failure) {
          error = failure.message;
          isLoading = false;
          notifyListeners();
          return null;
        },
        (url) {
          isLoading = false;
          notifyListeners();
          return url;
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

