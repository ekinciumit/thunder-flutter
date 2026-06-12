import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../user/domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/fetch_user_profile_usecase.dart';
import '../../domain/usecases/save_user_profile_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../../../services/crash_reporting_service.dart';

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
  bool _isDisposed = false; // Dispose kontrolü için flag

  final AuthRepository _authRepository;
  
  // Use Cases - Clean Architecture Domain Layer
  late final SignInUseCase _signInUseCase;
  late final SignUpUseCase _signUpUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final FetchUserProfileUseCase _fetchUserProfileUseCase;
  late final SaveUserProfileUseCase _saveUserProfileUseCase;
  late final DeleteAccountUseCase _deleteAccountUseCase;

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
    _deleteAccountUseCase = DeleteAccountUseCase(_authRepository);
  }
  
  /// Kullanıcıyı başlat
  /// 
  /// Uygulama başlangıcında veya hot reload sonrası çağrılır
  /// Firebase Auth'dan mevcut kullanıcıyı alır ve profil kontrolü yapar
  void _syncCrashReportingIdentity() {
    unawaited(CrashReportingService.setUserId(user?.uid));
  }

  void _initializeUser() {
    final currentUser = _authRepository.getCurrentUser();
    if (currentUser == null) {
      user = null;
      needsProfileCompletion = false;
      _syncCrashReportingIdentity();
      return;
    }
    
    // ✅ Hot reload durumunu kontrol et:
    // Eğer user zaten set edilmişse ve displayName varsa, hot reload durumudur
    // Bu durumda needsProfileCompletion'ı değiştirme, sadece Firestore'dan güncelle
    final isHotReload = user != null && 
                        user!.uid == currentUser.uid && 
                        user!.displayName != null && 
                        user!.displayName!.isNotEmpty;
    
    // Mevcut kullanıcıyı direkt kullan (getCurrentUser zaten UserEntity döndürüyor)
    user = currentUser;
    _syncCrashReportingIdentity();
    
    if (isHotReload) {
      // ✅ Hot reload durumu: needsProfileCompletion'ı değiştirme
      // Sadece Firestore'dan güncel profili çek (arka planda)
      if (kDebugMode) {
        debugPrint('✅ [AUTH_VM] Hot reload tespit edildi, needsProfileCompletion korunuyor: $needsProfileCompletion');
      }
      _loadUserProfileAsync(currentUser.uid);
    } else {
      // ✅ Yeni başlangıç: Cache'den kontrol et (async, ama init'te await edemeyiz)
      // Cache'de displayName varsa, needsProfileCompletion = false yap
      // Yoksa _loadUserProfileAsync tamamlandığında doğru değer set edilecek
      // unawaited kullanarak await etmeden çağırıyoruz (init'te await edemeyiz)
      unawaited(_checkCacheAndInitialize(currentUser.uid));
    }
  }
  
  /// Cache'den kontrol et ve initialize et
  /// 
  /// Cache'de displayName varsa, needsProfileCompletion = false yap
  /// Yoksa _loadUserProfileAsync çağır
  Future<void> _checkCacheAndInitialize(String uid) async {
    try {
      // Cache'den kontrol et (async, ama hızlı - repository cache'den kontrol ediyor)
      final cachedResult = await _fetchUserProfileUseCase(uid);
      final cachedProfile = cachedResult.fold(
        (failure) => null,
        (user) => user,
      );
      
      // ✅ Dispose kontrolü
      if (_isDisposed) return;
      
      if (cachedProfile != null && cachedProfile.displayName != null && cachedProfile.displayName!.isNotEmpty) {
        // ✅ Cache'de displayName var, profil tamamlanmış
        user = cachedProfile;
        needsProfileCompletion = false;
        
        if (kDebugMode) {
          debugPrint('✅ [AUTH_VM] Cache\'den profil yüklendi, needsProfileCompletion=false');
        }
        
        // ✅ Router'ın güncellenmesi için notifyListeners çağır
        if (!_isDisposed) {
          notifyListeners();
        }
        
        // Yine de Firestore'dan güncel profili çek (arka planda, güncellemeler için)
        _loadUserProfileAsync(uid);
      } else {
        // ✅ Cache'de displayName yok veya profil yok
        // Başlangıçta güvenli taraf: true (profil yüklendiğinde düzeltilecek)
        needsProfileCompletion = true;
        _loadUserProfileAsync(uid);
      }
    } catch (e) {
      // Cache kontrolü başarısız, direkt Firestore'dan yükle
      if (kDebugMode) {
        debugPrint('⚠️ [AUTH_VM] Cache kontrolü başarısız, Firestore\'dan yüklenecek: $e');
      }
      needsProfileCompletion = true;
      _loadUserProfileAsync(uid);
    }
  }
  
  /// Kullanıcı profilini asenkron olarak yükle ve needsProfileCompletion kontrolü yap
  Future<void> _loadUserProfileAsync(String uid) async {
    try {
      final profileResult = await _fetchUserProfileUseCase(uid);
      
      // ✅ Dispose kontrolü - ViewModel dispose edildiyse işlemi durdur
      if (_isDisposed) {
        if (kDebugMode) {
          debugPrint('⚠️ [AUTH_VM] _loadUserProfileAsync: ViewModel dispose edilmiş, işlem durduruldu');
        }
        return;
      }
      
      final profile = profileResult.fold(
        (failure) => null,
        (user) => user,
      );
      
      // ✅ Tekrar dispose kontrolü (async işlem sonrası)
      if (_isDisposed) {
        if (kDebugMode) {
          debugPrint('⚠️ [AUTH_VM] _loadUserProfileAsync: ViewModel dispose edilmiş, güncelleme yapılmıyor');
        }
        return;
      }
      
      if (profile != null) {
        user = profile;
        // ✅ Profil tamamlama kontrolü: displayName null veya boşsa tamamlama gerekli
        needsProfileCompletion = profile.displayName == null || profile.displayName!.isEmpty;
      } else {
        // Profil Firestore'da yoksa, tamamlama gerekli
        needsProfileCompletion = true;
      }
      
      // ✅ Son dispose kontrolü (notifyListeners öncesi)
      if (!_isDisposed) {
        notifyListeners(); // Profil yüklendikten sonra UI'ı güncelle
      }
    } catch (e) {
      // Hata durumunda sessizce devam et (offline olabilir)
      if (kDebugMode) {
        debugPrint('⚠️ [AUTH_VM] _loadUserProfileAsync hatası: $e');
      }
      // Offline durumda mevcut bilgiyle devam et, needsProfileCompletion değerini koru
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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
        _syncCrashReportingIdentity();
        unawaited(CrashReportingService.logEvent('login'));
        
        // ✅ Profil tamamlama kontrolü: displayName null veya boşsa tamamlama gerekli
        needsProfileCompletion = profile == null || 
                                 profile.displayName == null || 
                                 profile.displayName!.isEmpty;
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
        
        // ✅ Repository'de profil zaten Firestore'a kaydedildi ve Entity dönüldü
        // Gereksiz fetchUserProfile çağrısı yapmıyoruz (race condition önlenir)
        user = signedUpUser;
        _syncCrashReportingIdentity();
        unawaited(CrashReportingService.logEvent('sign_up'));
        
        // ✅ Yeni kullanıcı için profil tamamlama her zaman gerekli
        // Çünkü signUp sonrası kaydedilen profilde displayName null
        needsProfileCompletion = true;
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
    if (user == null) {
      if (kDebugMode) {
        debugPrint('❌ [AUTH_VM] completeProfile: user null!');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('✅ [AUTH_VM] completeProfile başlatılıyor: uid=${user!.uid}, displayName=$displayName');
    }
    
    isLoading = true;
    error = null;
    notifyListeners();
    
    // ✅ Önceki user state'ini sakla (rollback için)
    final previousUser = user;
    
    // ✅ Önce local state'i güncelle (optimistic update)
    user = UserEntity(
      uid: user!.uid,
      email: user!.email,
      displayName: displayName,
      username: user!.username,
      bio: bio,
      photoUrl: photoUrl ?? user!.photoUrl,
      followers: user!.followers,
      following: user!.following,
      fcmTokens: user!.fcmTokens,
      pendingFollowRequests: user!.pendingFollowRequests,
      sentFollowRequests: user!.sentFollowRequests,
      isPrivate: user!.isPrivate,
      showLocation: user!.showLocation,
      showOnlineStatus: user!.showOnlineStatus,
      blockedUsers: user!.blockedUsers,
    );
    
    try {
      // Clean Architecture: Use Case kullan
      if (kDebugMode) {
        debugPrint('✅ [AUTH_VM] saveUserProfileUseCase çağrılıyor...');
      }
      final result = await _saveUserProfileUseCase(user!);
          
      if (result.isRight) {
        if (kDebugMode) {
          debugPrint('✅ [AUTH_VM] saveUserProfileUseCase başarılı! Profil Firestore\'a kaydedildi.');
        }
        
        // ✅ Use Case başarılı - Profil Firestore'a kaydedildi
        // Firestore'dan güncel profili çek (tüm field'ların doğru olduğundan emin ol)
        if (kDebugMode) {
          debugPrint('✅ [AUTH_VM] Güncel profil çekiliyor...');
        }
        final profileResult = await _fetchUserProfileUseCase(user!.uid);
        final updatedProfile = profileResult.fold(
          (failure) {
            if (kDebugMode) {
              debugPrint('⚠️ [AUTH_VM] fetchUserProfile hatası: ${failure.message}');
            }
            return null;
          },
          (profile) {
            if (kDebugMode && profile != null) {
              final displayNameValue = profile.displayName ?? 'null';
              debugPrint('✅ [AUTH_VM] Profil başarıyla çekildi: displayName=$displayNameValue');
            } else if (kDebugMode) {
              debugPrint('⚠️ [AUTH_VM] Profil null döndü (Firestore\'da profil yok)');
            }
            return profile;
          },
        );
        
        if (updatedProfile != null) {
          user = updatedProfile;
          // ✅ Profil tamamlandı - displayName kontrolü
          needsProfileCompletion = updatedProfile.displayName == null || updatedProfile.displayName!.isEmpty;
        } else {
          // Profil çekilemedi ama kaydetme başarılı, local state'e güven
          needsProfileCompletion = false;
        }
        
        if (kDebugMode) {
          debugPrint('✅ [AUTH_VM] completeProfile başarılı! needsProfileCompletion=false, notifyListeners() çağrılıyor...');
        }
        
        // ✅ Router'ın refreshListenable mekanizması otomatik olarak redirect yapacak
        isLoading = false;
        notifyListeners();
      } else {
        // ❌ Use Case hata verdi
        final failure = result.left;
        error = failure.message;
        
        if (kDebugMode) {
          debugPrint('❌ [AUTH_VM] saveUserProfileUseCase hatası: ${failure.message}');
        }
        
        // Hata durumunda önceki user state'ine geri dön (rollback)
        user = previousUser;
        
        isLoading = false;
        notifyListeners();
        throw Exception(failure.message);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [AUTH_VM] completeProfile exception: $e');
        debugPrint('❌ [AUTH_VM] Stack trace: $stackTrace');
      }
      
      // Hata durumunda önceki user state'ine geri dön (rollback)
      user = previousUser;
      
      error = e.toString();
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount({required String password}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _deleteAccountUseCase(password: password);

      if (result.isRight) {
        user = null;
        needsProfileCompletion = false;
        justSignedUp = false;
        _syncCrashReportingIdentity();
        unawaited(CrashReportingService.logEvent('account_deleted'));
      } else {
        error = result.left.message;
        throw Exception(result.left.message);
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
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
        _syncCrashReportingIdentity();
        unawaited(CrashReportingService.logEvent('logout'));
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
      _syncCrashReportingIdentity();
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    if (user == null || _isDisposed) return;
    
    // ✅ Eğer profil zaten yüklenmişse (displayName var) ve loading değilse, tekrar yükleme
    // Sadece profil eksikse veya boşsa yükle
    if (user!.displayName != null && user!.displayName!.isNotEmpty && !isLoading) {
      if (kDebugMode) {
        debugPrint('✅ [AUTH_VM] loadUserProfile: Profil zaten yüklü, tekrar yüklenmiyor');
      }
      return;
    }
    
    isLoading = true;
    notifyListeners();
    
    try {
      // ✅ Dispose kontrolü
      if (_isDisposed) return;
      
      // Clean Architecture: Use Case kullan
      final result = await _fetchUserProfileUseCase(user!.uid);
      
      // ✅ Dispose kontrolü (async işlem sonrası)
      if (_isDisposed) {
        isLoading = false;
        return;
      }
          
      if (result.isRight) {
        // ✅ Use Case başarılı
        // Either'i güvenli bir şekilde aç (null değerleri destekle)
        final profile = result.fold(
          (failure) => null, // Hata durumunda null döndür
          (user) => user, // Başarılı durumda user'ı döndür (null olabilir)
        );
        if (profile != null) {
          user = profile;
          // ✅ Profil tamamlama kontrolü
          needsProfileCompletion = profile.displayName == null || profile.displayName!.isEmpty;
        }
      }
      // Hata durumunda sessizce devam et (profil bulunamadı, normal olabilir)
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AUTH_VM] loadUserProfile hatası: $e');
      }
      error = e.toString();
    } finally {
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
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

