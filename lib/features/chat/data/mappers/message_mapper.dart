import '../../domain/entities/message_entity.dart';
import '../models/message_model.dart' as model;

/// Message Entity <-> MessageModel (DTO) Mapper
/// 
/// Clean Architecture Data Layer
/// Domain entity ile data DTO arasında dönüşüm yapar
class MessageMapper {
  /// MessageModel (DTO) -> MessageEntity
  static MessageEntity toEntity(model.MessageModel messageModel) {
    return MessageEntity(
      id: messageModel.id,
      chatId: messageModel.chatId,
      senderId: messageModel.senderId,
      senderName: messageModel.senderName,
      senderPhotoUrl: messageModel.senderPhotoUrl,
      text: messageModel.text,
      type: messageTypeToEntity(messageModel.type),
      status: messageStatusToEntity(messageModel.status),
      timestamp: messageModel.timestamp,
      readAt: messageModel.readAt,
      imageUrl: messageModel.imageUrl,
      videoUrl: messageModel.videoUrl,
      audioUrl: messageModel.audioUrl,
      fileUrl: messageModel.fileUrl,
      fileName: messageModel.fileName,
      fileSize: messageModel.fileSize,
      gifUrl: messageModel.gifUrl,
      stickerUrl: messageModel.stickerUrl,
      location: messageModel.location,
      contact: messageModel.contact,
      replyToMessageId: messageModel.replyToMessageId,
      replyToMessage: messageModel.replyToMessage != null ? toEntity(messageModel.replyToMessage!) : null,
      forwardFromUserId: messageModel.forwardFromUserId,
      forwardFromUserName: messageModel.forwardFromUserName,
      reactions: messageModel.reactions,
      isEdited: messageModel.isEdited,
      editedAt: messageModel.editedAt,
      isDeleted: messageModel.isDeleted,
      deletedAt: messageModel.deletedAt,
      isPinned: messageModel.isPinned,
      pinnedAt: messageModel.pinnedAt,
      metadata: messageModel.metadata,
    );
  }

  /// MessageEntity -> MessageModel (DTO)
  static model.MessageModel toModel(MessageEntity entity) {
    return model.MessageModel(
      id: entity.id,
      chatId: entity.chatId,
      senderId: entity.senderId,
      senderName: entity.senderName,
      senderPhotoUrl: entity.senderPhotoUrl,
      text: entity.text,
      type: messageTypeToModel(entity.type),
      status: messageStatusToModel(entity.status),
      timestamp: entity.timestamp,
      readAt: entity.readAt,
      imageUrl: entity.imageUrl,
      videoUrl: entity.videoUrl,
      audioUrl: entity.audioUrl,
      fileUrl: entity.fileUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      gifUrl: entity.gifUrl,
      stickerUrl: entity.stickerUrl,
      location: entity.location,
      contact: entity.contact,
      replyToMessageId: entity.replyToMessageId,
      replyToMessage: entity.replyToMessage != null ? toModel(entity.replyToMessage!) : null,
      forwardFromUserId: entity.forwardFromUserId,
      forwardFromUserName: entity.forwardFromUserName,
      reactions: entity.reactions,
      isEdited: entity.isEdited,
      editedAt: entity.editedAt,
      isDeleted: entity.isDeleted,
      deletedAt: entity.deletedAt,
      isPinned: entity.isPinned,
      pinnedAt: entity.pinnedAt,
      metadata: entity.metadata,
    );
  }

  /// `List<MessageModel>` -> `List<MessageEntity>`
  static List<MessageEntity> toEntityList(List<model.MessageModel> models) {
    return models.map((m) => toEntity(m)).toList();
  }

  /// `List<MessageEntity>` -> `List<MessageModel>`
  static List<model.MessageModel> toModelList(List<MessageEntity> entities) {
    return entities.map((e) => toModel(e)).toList();
  }

  // Enum conversion helpers (public for repository use)
  static MessageType messageTypeToEntity(model.MessageType modelType) {
    // Enum değerlerini eşleştir
    switch (modelType) {
      case model.MessageType.text:
        return MessageType.text;
      case model.MessageType.image:
        return MessageType.image;
      case model.MessageType.video:
        return MessageType.video;
      case model.MessageType.audio:
        return MessageType.audio;
      case model.MessageType.gif:
        return MessageType.gif;
      case model.MessageType.sticker:
        return MessageType.sticker;
      case model.MessageType.file:
        return MessageType.file;
      case model.MessageType.location:
        return MessageType.location;
      case model.MessageType.contact:
        return MessageType.contact;
      case model.MessageType.reply:
        return MessageType.reply;
      case model.MessageType.forward:
        return MessageType.forward;
    }
  }

  static model.MessageType messageTypeToModel(MessageType entityType) {
    switch (entityType) {
      case MessageType.text:
        return model.MessageType.text;
      case MessageType.image:
        return model.MessageType.image;
      case MessageType.video:
        return model.MessageType.video;
      case MessageType.audio:
        return model.MessageType.audio;
      case MessageType.gif:
        return model.MessageType.gif;
      case MessageType.sticker:
        return model.MessageType.sticker;
      case MessageType.file:
        return model.MessageType.file;
      case MessageType.location:
        return model.MessageType.location;
      case MessageType.contact:
        return model.MessageType.contact;
      case MessageType.reply:
        return model.MessageType.reply;
      case MessageType.forward:
        return model.MessageType.forward;
    }
  }

  static MessageStatus messageStatusToEntity(model.MessageStatus modelStatus) {
    switch (modelStatus) {
      case model.MessageStatus.sending:
        return MessageStatus.sending;
      case model.MessageStatus.sent:
        return MessageStatus.sent;
      case model.MessageStatus.delivered:
        return MessageStatus.delivered;
      case model.MessageStatus.read:
        return MessageStatus.read;
      case model.MessageStatus.failed:
        return MessageStatus.failed;
    }
  }

  static model.MessageStatus messageStatusToModel(MessageStatus entityStatus) {
    switch (entityStatus) {
      case MessageStatus.sending:
        return model.MessageStatus.sending;
      case MessageStatus.sent:
        return model.MessageStatus.sent;
      case MessageStatus.delivered:
        return model.MessageStatus.delivered;
      case MessageStatus.read:
        return model.MessageStatus.read;
      case MessageStatus.failed:
        return model.MessageStatus.failed;
    }
  }
}

