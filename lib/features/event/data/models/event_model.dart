import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/location_entity.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final GeoPoint location;
  final String address;
  final DateTime datetime;
  final int quota;
  final String createdBy;
  final List<String> participants;
  final String? coverPhotoUrl;
  final String category;
  final List<String> pendingRequests; // Katılma isteği atan kullanıcılar
  final List<String> approvedParticipants; // Etkinliğe kabul edilenler
  final String status; // 'active', 'cancelled', 'completed'
  final DateTime? cancelledAt; // İptal tarihi
  final String? cancellationReason; // İptal sebebi

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.datetime,
    required this.quota,
    required this.createdBy,
    required this.participants,
    this.coverPhotoUrl,
    this.category = 'Diğer',
    this.pendingRequests = const [],
    this.approvedParticipants = const [],
    this.status = 'active',
    this.cancelledAt,
    this.cancellationReason,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'],
      address: map['address'] ?? '',
      datetime: (map['datetime'] as Timestamp).toDate(),
      quota: map['quota'] ?? 0,
      createdBy: map['createdBy'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      coverPhotoUrl: map['coverPhotoUrl'],
      category: map['category'] ?? 'Diğer',
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      approvedParticipants: List<String>.from(map['approvedParticipants'] ?? []),
      status: map['status'] ?? 'active',
      cancelledAt: map['cancelledAt'] != null ? (map['cancelledAt'] as Timestamp).toDate() : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'address': address,
      'datetime': Timestamp.fromDate(datetime),
      'quota': quota,
      'createdBy': createdBy,
      'participants': participants,
      'coverPhotoUrl': coverPhotoUrl,
      'category': category,
      'pendingRequests': pendingRequests,
      'approvedParticipants': approvedParticipants,
      'status': status,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    GeoPoint? location,
    String? address,
    DateTime? datetime,
    int? quota,
    String? createdBy,
    List<String>? participants,
    String? coverPhotoUrl,
    String? category,
    List<String>? pendingRequests,
    List<String>? approvedParticipants,
    String? status,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      datetime: datetime ?? this.datetime,
      quota: quota ?? this.quota,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      category: category ?? this.category,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      approvedParticipants: approvedParticipants ?? this.approvedParticipants,
      status: status ?? this.status,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
  
  // Helper getters
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  /// GeoPoint'i LocationEntity'ye çevirir (UI/Domain için)
  LocationEntity get locationEntity => LocationEntity(
        latitude: location.latitude,
        longitude: location.longitude,
      );

  /// LocationEntity'den GeoPoint oluşturur (Firestore için)
  static GeoPoint locationEntityToGeoPoint(LocationEntity locationEntity) {
    return GeoPoint(locationEntity.latitude, locationEntity.longitude);
  }
}

