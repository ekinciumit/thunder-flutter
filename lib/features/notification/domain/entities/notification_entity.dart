import 'package:equatable/equatable.dart';

/// Notification Priority Enum
enum NotificationPriorityEntity {
  critical,
  high,
  normal,
  low,
}

/// Notification Category Enum
enum NotificationCategoryEntity {
  critical,
  event,
  social,
  message,
  discovery,
}

/// Notification Type Constants
/// 
/// Clean Architecture Domain Layer
/// Pure Dart constants, no framework dependencies
class NotificationTypeEntity {
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
  
  static NotificationCategoryEntity getCategory(String type) {
    // Kritik
    if ([eventCancelled, eventLocationChanged, eventTimeChanged, 
         paymentFailed, accountSecurity].contains(type)) {
      return NotificationCategoryEntity.critical;
    }
    // Etkinlik
    if ([eventReminder24h, eventReminder2h, eventCheckIn, eventStarted,
         eventEnded, eventUpdated, eventInvitation, eventJoinRequest,
         eventJoinApproved, eventJoinRejected].contains(type)) {
      return NotificationCategoryEntity.event;
    }
    // Sosyal
    if ([followRequest, followRequestAccepted, newFollower, newFollowers,
         eventComment, eventLike, friendJoined].contains(type)) {
      return NotificationCategoryEntity.social;
    }
    // Mesaj
    if ([message, messageRequest, groupMessage].contains(type)) {
      return NotificationCategoryEntity.message;
    }
    // Keşif
    return NotificationCategoryEntity.discovery;
  }
  
  static NotificationPriorityEntity getPriority(String type) {
    // Kritik
    if ([eventCancelled, eventLocationChanged, eventTimeChanged,
         paymentFailed, accountSecurity].contains(type)) {
      return NotificationPriorityEntity.critical;
    }
    // Yüksek
    if ([followRequest, message, messageRequest, eventJoinRequest,
         eventCheckIn].contains(type)) {
      return NotificationPriorityEntity.high;
    }
    // Normal
    if ([eventReminder24h, eventReminder2h, eventJoinApproved,
         followRequestAccepted, eventInvitation].contains(type)) {
      return NotificationPriorityEntity.normal;
    }
    // Düşük
    return NotificationPriorityEntity.low;
  }
  
  static bool canBeGrouped(String type) {
    return [newFollower, eventLike, eventComment, friendJoined,
            eventRecommendation, nearbyEvent].contains(type);
  }
}

/// Notification Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart entity, Firebase bağımlılığı yok
class NotificationEntity extends Equatable {
  final String id;
  final String userId; // Bildirimi alan kullanıcı
  final String type; // NotificationTypeEntity değerlerinden biri
  final String? relatedUserId; // İlgili kullanıcı
  final String? relatedEventId; // İlgili etkinlik
  final String? relatedChatId; // İlgili sohbet
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Ek bilgiler (opsiyonel)
  final String? actionUrl; // Tıklandığında yönlendirilecek URL (opsiyonel)
  
  // Yeni alanlar
  final String? dedupKey; // Duplicate önleme: "EVENT_REMINDER:eventId:24h"
  final String? imageUrl; // Rich notification için görsel
  final String? actionLabel; // Buton metni: "Yol Tarifi", "Katıl" vb.
  final int? groupCount; // Gruplandırılmış bildirim sayısı
  final List<String>? groupedUserIds; // Gruplandırılmış kullanıcı ID'leri

  const NotificationEntity({
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

  @override
  List<Object?> get props => [
        id, userId, type, relatedUserId, relatedEventId, relatedChatId,
        title, body, isRead, createdAt, metadata, actionUrl,
        dedupKey, imageUrl, actionLabel, groupCount, groupedUserIds,
      ];

  NotificationEntity copyWith({
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
    return NotificationEntity(
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
  
  NotificationCategoryEntity get category => NotificationTypeEntity.getCategory(type);
  NotificationPriorityEntity get priority => NotificationTypeEntity.getPriority(type);
  bool get isCritical => priority == NotificationPriorityEntity.critical;
  bool get isHighPriority => priority == NotificationPriorityEntity.critical || priority == NotificationPriorityEntity.high;
  
  bool get requiresAction {
    return [
      NotificationTypeEntity.followRequest,
      NotificationTypeEntity.eventJoinRequest,
      NotificationTypeEntity.messageRequest,
      NotificationTypeEntity.eventInvitation,
    ].contains(type);
  }
  
  bool get isGrouped => groupCount != null && groupCount! > 1;
  bool get canBeGrouped => NotificationTypeEntity.canBeGrouped(type);
  
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
      case NotificationTypeEntity.eventCancelled:
        return '⚠️';
      case NotificationTypeEntity.eventLocationChanged:
      case NotificationTypeEntity.eventTimeChanged:
        return '📍';
      case NotificationTypeEntity.paymentFailed:
        return '💳';
      case NotificationTypeEntity.accountSecurity:
        return '🔒';
        
      // Etkinlik
      case NotificationTypeEntity.eventReminder24h:
      case NotificationTypeEntity.eventReminder2h:
        return '⏰';
      case NotificationTypeEntity.eventCheckIn:
        return '✅';
      case NotificationTypeEntity.eventStarted:
        return '🎉';
      case NotificationTypeEntity.eventEnded:
        return '⭐';
        
      // Sosyal
      case NotificationTypeEntity.followRequest:
      case NotificationTypeEntity.newFollower:
        return '👤';
      case NotificationTypeEntity.followRequestAccepted:
        return '🤝';
      case NotificationTypeEntity.eventComment:
        return '💬';
      case NotificationTypeEntity.eventLike:
        return '❤️';
        
      // Katılım
      case NotificationTypeEntity.eventInvitation:
        return '🎟️';
      case NotificationTypeEntity.eventJoinApproved:
        return '✨';
      case NotificationTypeEntity.friendJoined:
        return '👥';
        
      // Mesaj
      case NotificationTypeEntity.message:
      case NotificationTypeEntity.messageRequest:
        return '💬';
        
      // Keşif
      case NotificationTypeEntity.eventRecommendation:
      case NotificationTypeEntity.nearbyEvent:
        return '🔍';
      case NotificationTypeEntity.weeklyDigest:
        return '📊';
        
      default:
        return '';
    }
  }
}

