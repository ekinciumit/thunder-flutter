/// Dependency Injection Container (Service Locator)
/// 
/// Bu sınıf SOLID prensiplerinden Dependency Inversion Principle'a uyar:
/// - Yüksek seviye modüller düşük seviye modüllere bağımlı olmaz
/// - Abstract interface'lere bağımlı olur

/// Service Locator pattern implementation
library;
/// 
/// Servisleri merkezi bir yerde yönetir ve ihtiyaç duyulan yerde sağlar.
/// Bu sayede:
/// - Test edilebilirlik artar (mock servisler eklenebilir)
/// - Bağımlılıklar merkezi yönetilir
/// - Kod daha modüler hale gelir
class ServiceLocator {
  // Singleton pattern
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Servisleri saklamak için map
  final Map<Type, dynamic> _services = {};
  
  // Factory fonksiyonlarını saklamak için map
  final Map<Type, dynamic Function()> _factories = {};

  /// Singleton servis kaydet
  /// 
  /// Bu servis bir kez oluşturulur ve her çağrıda aynı instance döner.
  /// 
  /// Örnek:
  /// ```dart
  /// ServiceLocator().registerSingleton<IAuthService>(AuthService());
  /// ```
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// Factory servis kaydet
  /// 
  /// Bu servis her çağrıda yeni bir instance oluşturulur.
  /// 
  /// Örnek:
  /// ```dart
  /// ServiceLocator().registerFactory<IAuthService>(() => AuthService());
  /// ```
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Servis al
  /// 
  /// Önce singleton'lara bakar, sonra factory'lere bakar.
  /// 
  /// Örnek:
  /// ```dart
  /// final authService = ServiceLocator().get<IAuthService>();
  /// ```
  /// 
  /// Throws: Exception if service not found
  T get<T>() {
    // Önce singleton'lara bak
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }
    
    // Sonra factory'lere bak
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }
    
    throw Exception('Service $T not registered. Call registerSingleton or registerFactory first.');
  }

  /// Servis var mı kontrol et
  /// 
  /// Returns: true if service is registered, false otherwise
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Tüm servisleri temizle (test için)
  /// 
  /// DİKKAT: Bu metod sadece test ortamında kullanılmalıdır!
  void reset() {
    _services.clear();
    _factories.clear();
  }
}

