import 'dart:math' as math;

/// Location Entity
/// 
/// Clean Architecture Domain Layer
/// Firestore GeoPoint'ten bağımsız, pure Dart entity.
class LocationEntity {
  final double latitude;
  final double longitude;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
  });

  /// İki lokasyon arasındaki mesafeyi kilometre cinsinden hesaplar (Haversine formula)
  double distanceTo(LocationEntity other) {
    const double earthRadiusKm = 6371.0;
    
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) * 
        math.cos(_toRadians(other.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (3.141592653589793 / 180.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationEntity &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LocationEntity(lat: $latitude, lng: $longitude)';
}

