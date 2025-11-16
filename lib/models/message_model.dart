import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  gif,
  sticker,
  file,
  location,
  contact,
  reply,
  forward,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String? text;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? gifUrl;
  final String? stickerUrl;
  final Map<String, dynamic>? location;
  final Map<String, dynamic>? contact;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  final String? forwardFromUserId;
  final String? forwardFromUserName;
  final Map<String, List<String>> reactions; // userId -> [emoji1, emoji2]
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isPinned;
  final DateTime? pinnedAt;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    this.text,
    required this.type,
    required this.status,
    required this.timestamp,
    this.readAt,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.gifUrl,
    this.stickerUrl,
    this.location,
    this.contact,
    this.replyToMessageId,
    this.replyToMessage,
    this.forwardFromUserId,
    this.forwardFromUserName,
    this.reactions = const {},
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.metadata,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      text: map['text'],
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      audioUrl: map['audioUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      gifUrl: map['gifUrl'],
      stickerUrl: map['stickerUrl'],
      location: map['location'],
      contact: map['contact'],
      replyToMessageId: map['replyToMessageId'],
      forwardFromUserId: map['forwardFromUserId'],
      forwardFromUserName: map['forwardFromUserName'],
      reactions: _parseReactions(map['reactions']),
      isEdited: map['isEdited'] ?? false,
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      isPinned: map['isPinned'] ?? false,
      pinnedAt: (map['pinnedAt'] as Timestamp?)?.toDate(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'gifUrl': gifUrl,
      'stickerUrl': stickerUrl,
      'location': location,
      'contact': contact,
      'replyToMessageId': replyToMessageId,
      'forwardFromUserId': forwardFromUserId,
      'forwardFromUserName': forwardFromUserName,
      'reactions': reactions,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'isPinned': isPinned,
      'pinnedAt': pinnedAt != null ? Timestamp.fromDate(pinnedAt!) : null,
      'metadata': metadata,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? text,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? gifUrl,
    String? stickerUrl,
    Map<String, dynamic>? location,
    Map<String, dynamic>? contact,
    String? replyToMessageId,
    MessageModel? replyToMessage,
    String? forwardFromUserId,
    String? forwardFromUserName,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isPinned,
    DateTime? pinnedAt,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      gifUrl: gifUrl ?? this.gifUrl,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      forwardFromUserId: forwardFromUserId ?? this.forwardFromUserId,
      forwardFromUserName: forwardFromUserName ?? this.forwardFromUserName,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Reactions'ı parse et (Firestore'dan gelen dynamic list'i String list'e çevir)
  static Map<String, List<String>> _parseReactions(dynamic reactionsData) {
    if (reactionsData == null || reactionsData is! Map) {
      return {};
    }
    
    final Map<String, List<String>> parsed = {};
    reactionsData.forEach((key, value) {
      if (value is List) {
        parsed[key.toString()] = value.map((e) => e.toString()).toList();
      }
    });
    return parsed;
  }
}



