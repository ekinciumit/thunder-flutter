/// Message Type Enum
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

/// Message Status Enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Message Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart entity, Firebase bağımlılığı yok
class MessageEntity {
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
  final MessageEntity? replyToMessage;
  final String? forwardFromUserId;
  final String? forwardFromUserName;
  final Map<String, List<String>> reactions;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isPinned;
  final DateTime? pinnedAt;
  final Map<String, dynamic>? metadata;

  const MessageEntity({
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

  MessageEntity copyWith({
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
    MessageEntity? replyToMessage,
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
    return MessageEntity(
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
      other is MessageEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MessageEntity(id: $id, chatId: $chatId, type: $type)';
}

