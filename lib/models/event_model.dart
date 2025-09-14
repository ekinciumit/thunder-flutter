import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
  }
} 