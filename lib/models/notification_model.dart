import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId; // Bildirimi alan kullanıcı
  final String type; // 'follow', 'event', 'message', etc.
  final String? relatedUserId; // Takip eden kullanıcı (follow için)
  final String? relatedEventId; // İlgili etkinlik (event için)
  final String? relatedChatId; // İlgili sohbet (message için)
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.relatedUserId,
    this.relatedEventId,
    this.relatedChatId,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      relatedUserId: map['relatedUserId'],
      relatedEventId: map['relatedEventId'],
      relatedChatId: map['relatedChatId'],
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'relatedUserId': relatedUserId,
      'relatedEventId': relatedEventId,
      'relatedChatId': relatedChatId,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? relatedUserId,
    String? relatedEventId,
    String? relatedChatId,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedEventId: relatedEventId ?? this.relatedEventId,
      relatedChatId: relatedChatId ?? this.relatedChatId,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

