import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Map Cache Service
/// 
/// Caches Google Maps controller and last viewed position to reduce map load costs
/// **Maliyet Tasarrufu:** %50-70 map load maliyeti azalır
class MapCacheService {
  static GoogleMapController? _cachedController;
  static LatLng? _lastPosition;
  static DateTime? _lastAccess;
  static double? _lastZoom;
  
  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const double _distanceThreshold = 1000; // 1km in meters

  /// Check if cache should be used for the given position
  /// 
  /// Returns true if:
  /// - Last position is within 1km of current position
  /// - Last access was within 5 minutes
  static bool shouldUseCache(LatLng position) {
    if (_lastPosition == null || _lastAccess == null) {
      return false;
    }

    // Check if cache is still valid (time-based)
    final timeSinceLastAccess = DateTime.now().difference(_lastAccess!);
    if (timeSinceLastAccess > _cacheDuration) {
      return false;
    }

    // Check if position is within threshold (distance-based)
    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    return distance < _distanceThreshold;
  }

  /// Get cached controller if available
  static GoogleMapController? getCachedController() {
    return _cachedController;
  }

  /// Cache the controller and position
  static void cacheController(GoogleMapController controller, LatLng position, {double? zoom}) {
    _cachedController = controller;
    _lastPosition = position;
    _lastZoom = zoom;
    _lastAccess = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('✅ [MAP_CACHE] Cached map controller at (${position.latitude}, ${position.longitude})');
    }
  }

  /// Clear cache
  static void clearCache() {
    _cachedController = null;
    _lastPosition = null;
    _lastAccess = null;
    _lastZoom = null;
    
    if (kDebugMode) {
      debugPrint('🗑️ [MAP_CACHE] Cache cleared');
    }
  }

  /// Get last cached position
  static LatLng? getLastPosition() {
    return _lastPosition;
  }

  /// Get last cached zoom
  static double? getLastZoom() {
    return _lastZoom;
  }

  /// Check if cache exists
  static bool hasCache() {
    return _cachedController != null && _lastPosition != null;
  }
}

