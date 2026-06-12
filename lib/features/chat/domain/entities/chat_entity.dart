import 'message_entity.dart';

/// Chat Type Enum
/// 
/// Clean Architecture Domain Layer
/// Pure Dart enum, Firestore bağımsız
enum ChatType {
  private,
  group,
  channel,
}

/// Chat Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart class, Firestore bağımsız
/// Domain business logic içerebilir
class ChatEntity {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final ChatType type;
  final List<String> participants;
  final Map<String, ChatParticipantEntity> participantDetails;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final MessageEntity? lastMessage;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, DateTime> lastSeen; // userId -> last seen timestamp
  final Map<String, bool> typingStatus; // userId -> is typing
  final List<String> admins;
  final List<String> moderators;
  final bool isArchived;
  final bool isMuted;
  final Map<String, bool> mutedBy; // userId -> is muted (deprecated, use mutedUntil)
  final Map<String, DateTime?> mutedUntil; // userId -> mute end time (null = unlimited)
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  ChatEntity({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    required this.type,
    required this.participants,
    this.participantDetails = const {},
    this.createdBy,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCounts = const {},
    this.lastSeen = const {},
    this.typingStatus = const {},
    this.admins = const [],
    this.moderators = const [],
    this.isArchived = false,
    this.isMuted = false,
    this.mutedBy = const {},
    this.mutedUntil = const {},
    this.settings,
    this.metadata,
  });

  /// Copy with method for immutable updates
  ChatEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    ChatType? type,
    List<String>? participants,
    Map<String, ChatParticipantEntity>? participantDetails,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    MessageEntity? lastMessage,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastSeen,
    Map<String, bool>? typingStatus,
    List<String>? admins,
    List<String>? moderators,
    bool? isArchived,
    bool? isMuted,
    Map<String, bool>? mutedBy,
    Map<String, DateTime?>? mutedUntil,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ChatEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      participantDetails: participantDetails ?? this.participantDetails,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastSeen: lastSeen ?? this.lastSeen,
      typingStatus: typingStatus ?? this.typingStatus,
      admins: admins ?? this.admins,
      moderators: moderators ?? this.moderators,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      mutedBy: mutedBy ?? this.mutedBy,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper methods for domain logic
  
  /// Kullanıcının okunmamış mesaj sayısını döndürür
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  /// Kullanıcı admin mi kontrol eder
  bool isAdmin(String userId) {
    return admins.contains(userId);
  }

  /// Kullanıcı grup oluşturan mı kontrol eder
  bool isCreator(String userId) {
    return createdBy == userId;
  }

  /// Kullanıcı grup yöneticisi mi kontrol eder (oluşturan veya admin)
  bool isGroupAdmin(String userId) {
    return isCreator(userId) || isAdmin(userId);
  }

  /// Kullanıcı grup bilgilerini düzenleyebilir mi (sadece yöneticiler)
  bool canEditGroup(String userId) {
    return isGroupAdmin(userId);
  }

  /// Kullanıcı yönetici yapabilir/çıkarabilir mi (sadece yöneticiler)
  bool canManageAdmins(String userId) {
    return isGroupAdmin(userId);
  }

  /// Kullanıcı üye ekleyebilir/çıkarabilir mi (sadece yöneticiler)
  bool canManageMembers(String userId) {
    return isGroupAdmin(userId);
  }

  /// Kullanıcı moderator mü kontrol eder
  bool isModerator(String userId) {
    return moderators.contains(userId);
  }

  /// Kullanıcı sohbette mi kontrol eder
  bool hasParticipant(String userId) {
    return participants.contains(userId);
  }

  /// Kullanıcı sohbeti susturmuş mu kontrol eder (deprecated, use isMutedUntil)
  bool isMutedBy(String userId) {
    return mutedBy[userId] ?? false;
  }

  /// Kullanıcı sohbeti susturmuş mu kontrol eder (mutedUntil kullanarak)
  bool isMutedUntil(String userId) {
    final muteEndTime = mutedUntil[userId];
    if (muteEndTime == null) {
      // null = süresiz sessize alınmış
      return mutedBy[userId] ?? false; // Eski sistemle uyumluluk için
    }
    // Süre dolmuş mu kontrol et
    return DateTime.now().isBefore(muteEndTime);
  }

  /// Sohbet aktif mi kontrol eder (arşivlenmemiş)
  bool get isActive => !isArchived;
}

/// Chat Participant Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart class, Firestore bağımsız
class ChatParticipantEntity {
  final String userId;
  final String name;
  final String? photoUrl;
  final DateTime joinedAt;
  final String? role; // admin, moderator, member
  final bool isActive;
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  ChatParticipantEntity({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.joinedAt,
    this.role,
    this.isActive = true,
    this.lastSeen,
    this.metadata,
  });

  /// Copy with method for immutable updates
  ChatParticipantEntity copyWith({
    String? userId,
    String? name,
    String? photoUrl,
    DateTime? joinedAt,
    String? role,
    bool? isActive,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return ChatParticipantEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper methods for domain logic
  
  /// Kullanıcı admin mi kontrol eder
  bool get isAdminRole => role == 'admin';

  /// Kullanıcı moderator mü kontrol eder
  bool get isModeratorRole => role == 'moderator';

  /// Kullanıcı normal üye mi kontrol eder
  bool get isMemberRole => role == null || role == 'member';
}

