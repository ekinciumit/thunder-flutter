import 'location_entity.dart';

/// Event Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart entity, Firebase bağımlılığı yok
class EventEntity {
  final String id;
  final String title;
  final String description;
  final LocationEntity location; // GeoPoint yerine LocationEntity
  final String address;
  final DateTime datetime;
  final int quota;
  final String createdBy;
  final List<String> participants;
  final String? coverPhotoUrl;
  final String category;
  final List<String> pendingRequests;
  final List<String> approvedParticipants;
  final String status; // 'active', 'cancelled', 'completed'
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const EventEntity({
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

  // Helper getters
  bool get isCancelled => status == 'cancelled';
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    LocationEntity? location,
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
    return EventEntity(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EventEntity(id: $id, title: $title, datetime: $datetime)';
}

