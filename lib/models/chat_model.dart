import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

enum ChatType {
  private,
  group,
  channel,
}

class ChatModel {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final ChatType type;
  final List<String> participants;
  final Map<String, ChatParticipant> participantDetails;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final MessageModel? lastMessage;
  final Map<String, int> unreadCounts; // userId -> unread count
  final Map<String, DateTime> lastSeen; // userId -> last seen timestamp
  final Map<String, bool> typingStatus; // userId -> is typing
  final List<String> admins;
  final List<String> moderators;
  final bool isArchived;
  final bool isMuted;
  final Map<String, bool> mutedBy; // userId -> is muted
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  ChatModel({
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
    this.settings,
    this.metadata,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      photoUrl: map['photoUrl'],
      type: ChatType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChatType.private,
      ),
      participants: List<String>.from(map['participants'] ?? []),
      participantDetails: (map['participantDetails'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, ChatParticipant.fromMap(value)),
      ) ?? {},
      createdBy: map['createdBy'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessage: map['lastMessage'] != null ? MessageModel.fromMap(map['lastMessage'], '') : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      lastSeen: (map['lastSeen'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ) ?? {},
      typingStatus: Map<String, bool>.from(map['typingStatus'] ?? {}),
      admins: List<String>.from(map['admins'] ?? []),
      moderators: List<String>.from(map['moderators'] ?? []),
      isArchived: map['isArchived'] ?? false,
      isMuted: map['isMuted'] ?? false,
      mutedBy: Map<String, bool>.from(map['mutedBy'] ?? {}),
      settings: map['settings'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'type': type.name,
      'participants': participants,
      'participantDetails': participantDetails.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage?.toMap(),
      'unreadCounts': unreadCounts,
      'lastSeen': lastSeen.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'typingStatus': typingStatus,
      'admins': admins,
      'moderators': moderators,
      'isArchived': isArchived,
      'isMuted': isMuted,
      'mutedBy': mutedBy,
      'settings': settings,
      'metadata': metadata,
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photoUrl,
    ChatType? type,
    List<String>? participants,
    Map<String, ChatParticipant>? participantDetails,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    MessageModel? lastMessage,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastSeen,
    Map<String, bool>? typingStatus,
    List<String>? admins,
    List<String>? moderators,
    bool? isArchived,
    bool? isMuted,
    Map<String, bool>? mutedBy,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
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
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatParticipant {
  final String userId;
  final String name;
  final String? photoUrl;
  final DateTime joinedAt;
  final String? role; // admin, moderator, member
  final bool isActive;
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  ChatParticipant({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.joinedAt,
    this.role,
    this.isActive = true,
    this.lastSeen,
    this.metadata,
  });

  factory ChatParticipant.fromMap(Map<String, dynamic> map) {
    return ChatParticipant(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'],
      isActive: map['isActive'] ?? true,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role,
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'metadata': metadata,
    };
  }
}

