import 'package:firebase_auth/firebase_auth.dart';

/// Hata mesajlarını kullanıcı dostu mesajlara çeviren sınıf
/// 
/// Bu sınıf SOLID prensiplerinden Single Responsibility Principle'a uyar:
/// - Sadece hata mesajı mapping'den sorumlu
/// - Başka hiçbir iş yapmaz
/// 
/// ŞU AN: Bu sınıf sadece ekleniyor, mevcut kod çalışmaya devam ediyor
class ErrorMapper {
  /// Firebase Auth hatalarını Türkçe mesajlara çevirir
  /// 
  /// Bu metod AuthService içindeki _mapFirebaseAuthException metodunun
  /// merkezi bir versiyonudur. Şu an mevcut kod çalışmaya devam ediyor,
  /// bu sınıfı kullanmak için hazırlıyoruz.
  static String mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Girdiğiniz şifre yanlış. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      case 'weak-password':
        return 'Şifreniz çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'network-request-failed':
        return 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış. Lütfen destek ekibi ile iletişime geçin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      default:
        return 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
    }
  }

  /// Genel hataları kullanıcı dostu mesajlara çevirir
  /// 
  /// Bu metod farklı türdeki hataları (network, timeout, permission vb.)
  /// kullanıcı dostu mesajlara çevirir.
  static String mapGenericError(dynamic error) {
    // Firebase Auth hatası ise özel metodunu kullan
    if (error is FirebaseAuthException) {
      return mapFirebaseAuthException(error);
    }
    
    // Hata mesajını küçük harfe çevir (karşılaştırma için)
    final errorString = error.toString().toLowerCase();
    
    // Network hatası kontrolü
    if (errorString.contains('network') || errorString.contains('internet')) {
      return 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.';
    }
    
    // Timeout hatası kontrolü
    if (errorString.contains('timeout')) {
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    }
    
    // Permission hatası kontrolü
    if (errorString.contains('permission')) {
      return 'Bu işlem için yetkiniz bulunmamaktadır.';
    }
    
    // Bilinmeyen hata için varsayılan mesaj
    return 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
  }
}

