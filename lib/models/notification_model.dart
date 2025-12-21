import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationPriority { critical, high, normal, low }

enum NotificationCategory { critical, event, social, message, discovery }

class NotificationType {
  // Critical
  static const String eventCancelled = 'event_cancelled';
  static const String eventLocationChanged = 'event_location_changed';
  static const String eventTimeChanged = 'event_time_changed';
  static const String paymentFailed = 'payment_failed';
  static const String accountSecurity = 'account_security';
  
  // Event flow
  static const String eventReminder24h = 'event_reminder_24h';
  static const String eventReminder2h = 'event_reminder_2h';
  static const String eventCheckIn = 'event_check_in';
  static const String eventStarted = 'event_started';
  static const String eventEnded = 'event_ended';
  static const String eventUpdated = 'event_updated';
  
  // Social
  static const String followRequest = 'follow_request';
  static const String followRequestAccepted = 'follow_request_accepted';
  static const String newFollower = 'new_follower';
  static const String newFollowers = 'new_followers';
  static const String eventComment = 'event_comment';
  static const String eventLike = 'event_like';
  
  // Participation
  static const String eventInvitation = 'event_invitation';
  static const String eventJoinRequest = 'event_join_request';
  static const String eventJoinApproved = 'event_join_approved';
  static const String eventJoinRejected = 'event_join_rejected';
  static const String friendJoined = 'friend_joined';
  
  // Messages
  static const String message = 'message';
  static const String messageRequest = 'message_request';
  static const String groupMessage = 'group_message';
  
  // Discovery
  static const String eventRecommendation = 'event_recommendation';
  static const String nearbyEvent = 'nearby_event';
  static const String weeklyDigest = 'weekly_digest';
  static const String friendsAttending = 'friends_attending';
  
  // System
  static const String system = 'system';
  static const String appUpdate = 'app_update';
  static const String mention = 'mention';
  
  static NotificationCategory getCategory(String type) {
    // Kritik
    if ([eventCancelled, eventLocationChanged, eventTimeChanged, 
         paymentFailed, accountSecurity].contains(type)) {
      return NotificationCategory.critical;
    }
    // Etkinlik
    if ([eventReminder24h, eventReminder2h, eventCheckIn, eventStarted,
         eventEnded, eventUpdated, eventInvitation, eventJoinRequest,
         eventJoinApproved, eventJoinRejected].contains(type)) {
      return NotificationCategory.event;
    }
    // Sosyal
    if ([followRequest, followRequestAccepted, newFollower, newFollowers,
         eventComment, eventLike, friendJoined].contains(type)) {
      return NotificationCategory.social;
    }
    // Mesaj
    if ([message, messageRequest, groupMessage].contains(type)) {
      return NotificationCategory.message;
    }
    // Keşif
    return NotificationCategory.discovery;
  }
  
  static NotificationPriority getPriority(String type) {
    // Kritik
    if ([eventCancelled, eventLocationChanged, eventTimeChanged,
         paymentFailed, accountSecurity].contains(type)) {
      return NotificationPriority.critical;
    }
    // Yüksek
    if ([followRequest, message, messageRequest, eventJoinRequest,
         eventCheckIn].contains(type)) {
      return NotificationPriority.high;
    }
    // Normal
    if ([eventReminder24h, eventReminder2h, eventJoinApproved,
         followRequestAccepted, eventInvitation].contains(type)) {
      return NotificationPriority.normal;
    }
    // Düşük
    return NotificationPriority.low;
  }
  
  static bool canBeGrouped(String type) {
    return [newFollower, eventLike, eventComment, friendJoined,
            eventRecommendation, nearbyEvent].contains(type);
  }
}

class NotificationModel {
  final String id;
  final String userId; // Bildirimi alan kullanıcı
  final String type; // NotificationType değerlerinden biri
  final String? relatedUserId; // İlgili kullanıcı
  final String? relatedEventId; // İlgili etkinlik
  final String? relatedChatId; // İlgili sohbet
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Ek bilgiler (opsiyonel)
  final String? actionUrl; // Tıklandığında yönlendirilecek URL (opsiyonel)
  
  // Yeni alanlar (ChatGPT önerilerine göre)
  final String? dedupKey; // Duplicate önleme: "EVENT_REMINDER:eventId:24h"
  final String? imageUrl; // Rich notification için görsel
  final String? actionLabel; // Buton metni: "Yol Tarifi", "Katıl" vb.
  final int? groupCount; // Gruplandırılmış bildirim sayısı
  final List<String>? groupedUserIds; // Gruplandırılmış kullanıcı ID'leri

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
    this.metadata,
    this.actionUrl,
    this.dedupKey,
    this.imageUrl,
    this.actionLabel,
    this.groupCount,
    this.groupedUserIds,
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
      metadata: map['metadata'],
      actionUrl: map['actionUrl'],
      dedupKey: map['dedupKey'],
      imageUrl: map['imageUrl'],
      actionLabel: map['actionLabel'],
      groupCount: map['groupCount'],
      groupedUserIds: map['groupedUserIds'] != null 
          ? List<String>.from(map['groupedUserIds']) 
          : null,
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
      if (metadata != null) 'metadata': metadata,
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (dedupKey != null) 'dedupKey': dedupKey,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionLabel != null) 'actionLabel': actionLabel,
      if (groupCount != null) 'groupCount': groupCount,
      if (groupedUserIds != null) 'groupedUserIds': groupedUserIds,
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
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? dedupKey,
    String? imageUrl,
    String? actionLabel,
    int? groupCount,
    List<String>? groupedUserIds,
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
      metadata: metadata ?? this.metadata,
      actionUrl: actionUrl ?? this.actionUrl,
      dedupKey: dedupKey ?? this.dedupKey,
      imageUrl: imageUrl ?? this.imageUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      groupCount: groupCount ?? this.groupCount,
      groupedUserIds: groupedUserIds ?? this.groupedUserIds,
    );
  }
  
  NotificationCategory get category => NotificationType.getCategory(type);
  NotificationPriority get priority => NotificationType.getPriority(type);
  bool get isCritical => priority == NotificationPriority.critical;
  bool get isHighPriority => priority == NotificationPriority.critical || priority == NotificationPriority.high;
  
  bool get requiresAction {
    return [
      NotificationType.followRequest,
      NotificationType.eventJoinRequest,
      NotificationType.messageRequest,
      NotificationType.eventInvitation,
    ].contains(type);
  }
  
  bool get isGrouped => groupCount != null && groupCount! > 1;
  bool get canBeGrouped => NotificationType.canBeGrouped(type);
  
  static String createDedupKey(String type, String? entityId, [String? suffix]) {
    final parts = [type];
    if (entityId != null) parts.add(entityId);
    if (suffix != null) parts.add(suffix);
    return parts.join(':');
  }
  
  String get formattedBody {
    final emoji = _getTypeEmoji(type);
    return emoji.isNotEmpty ? '$emoji $body' : body;
  }
  
  String _getTypeEmoji(String type) {
    switch (type) {
      // Kritik
      case NotificationType.eventCancelled:
        return '⚠️';
      case NotificationType.eventLocationChanged:
      case NotificationType.eventTimeChanged:
        return '📍';
      case NotificationType.paymentFailed:
        return '💳';
      case NotificationType.accountSecurity:
        return '🔒';
        
      // Etkinlik
      case NotificationType.eventReminder24h:
      case NotificationType.eventReminder2h:
        return '⏰';
      case NotificationType.eventCheckIn:
        return '✅';
      case NotificationType.eventStarted:
        return '🎉';
      case NotificationType.eventEnded:
        return '⭐';
        
      // Sosyal
      case NotificationType.followRequest:
      case NotificationType.newFollower:
        return '👤';
      case NotificationType.followRequestAccepted:
        return '🤝';
      case NotificationType.eventComment:
        return '💬';
      case NotificationType.eventLike:
        return '❤️';
        
      // Katılım
      case NotificationType.eventInvitation:
        return '🎟️';
      case NotificationType.eventJoinApproved:
        return '✨';
      case NotificationType.friendJoined:
        return '👥';
        
      // Mesaj
      case NotificationType.message:
      case NotificationType.messageRequest:
        return '💬';
        
      // Keşif
      case NotificationType.eventRecommendation:
      case NotificationType.nearbyEvent:
        return '🔍';
      case NotificationType.weeklyDigest:
        return '📊';
        
      default:
        return '';
    }
  }
}

