import '../../domain/entities/chat_entity.dart' as entity;
import '../models/chat_model.dart' as model;
import 'message_mapper.dart';

/// Chat Entity <-> ChatModel (DTO) Mapper
/// 
/// Clean Architecture Data Layer
/// Domain entity ile data DTO arasında dönüşüm yapar
class ChatMapper {
  /// ChatModel (DTO) -> ChatEntity
  static entity.ChatEntity toEntity(model.ChatModel chatModel) {
    return entity.ChatEntity(
      id: chatModel.id,
      name: chatModel.name,
      description: chatModel.description,
      photoUrl: chatModel.photoUrl,
      type: _chatTypeToEntity(chatModel.type),
      participants: chatModel.participants,
      participantDetails: chatModel.participantDetails.map(
        (key, value) => MapEntry(key, _participantToEntity(value)),
      ),
      createdBy: chatModel.createdBy,
      createdAt: chatModel.createdAt,
      lastMessageAt: chatModel.lastMessageAt,
      lastMessage: chatModel.lastMessage != null 
          ? MessageMapper.toEntity(chatModel.lastMessage!) 
          : null,
      unreadCounts: chatModel.unreadCounts,
      lastSeen: chatModel.lastSeen,
      typingStatus: chatModel.typingStatus,
      admins: chatModel.admins,
      moderators: chatModel.moderators,
      isArchived: chatModel.isArchived,
      isMuted: chatModel.isMuted,
      mutedBy: chatModel.mutedBy,
      settings: chatModel.settings,
      metadata: chatModel.metadata,
    );
  }

  /// ChatEntity -> ChatModel (DTO)
  static model.ChatModel toModel(entity.ChatEntity chatEntity) {
    return model.ChatModel(
      id: chatEntity.id,
      name: chatEntity.name,
      description: chatEntity.description,
      photoUrl: chatEntity.photoUrl,
      type: _chatTypeToModel(chatEntity.type),
      participants: chatEntity.participants,
      participantDetails: chatEntity.participantDetails.map(
        (key, value) => MapEntry(key, _participantToModel(value)),
      ),
      createdBy: chatEntity.createdBy,
      createdAt: chatEntity.createdAt,
      lastMessageAt: chatEntity.lastMessageAt,
      lastMessage: chatEntity.lastMessage != null 
          ? MessageMapper.toModel(chatEntity.lastMessage!) 
          : null,
      unreadCounts: chatEntity.unreadCounts,
      lastSeen: chatEntity.lastSeen,
      typingStatus: chatEntity.typingStatus,
      admins: chatEntity.admins,
      moderators: chatEntity.moderators,
      isArchived: chatEntity.isArchived,
      isMuted: chatEntity.isMuted,
      mutedBy: chatEntity.mutedBy,
      settings: chatEntity.settings,
      metadata: chatEntity.metadata,
    );
  }

  /// `List<ChatModel>` -> `List<ChatEntity>`
  static List<entity.ChatEntity> toEntityList(List<model.ChatModel> models) {
    return models.map((m) => toEntity(m)).toList();
  }

  /// `List<ChatEntity>` -> `List<ChatModel>`
  static List<model.ChatModel> toModelList(List<entity.ChatEntity> entities) {
    return entities.map((e) => toModel(e)).toList();
  }

  /// ChatType enum dönüşümü (Model -> Entity)
  static entity.ChatType _chatTypeToEntity(model.ChatType modelType) {
    // Enum değerleri aynı olduğu için direkt döndürülebilir
    // Ama type safety için explicit mapping yapıyoruz
    switch (modelType) {
      case model.ChatType.private:
        return entity.ChatType.private;
      case model.ChatType.group:
        return entity.ChatType.group;
      case model.ChatType.channel:
        return entity.ChatType.channel;
    }
  }

  /// ChatType enum dönüşümü (Entity -> Model)
  static model.ChatType _chatTypeToModel(entity.ChatType entityType) {
    // Enum değerleri aynı olduğu için direkt döndürülebilir
    // Ama type safety için explicit mapping yapıyoruz
    switch (entityType) {
      case entity.ChatType.private:
        return model.ChatType.private;
      case entity.ChatType.group:
        return model.ChatType.group;
      case entity.ChatType.channel:
        return model.ChatType.channel;
    }
  }

  /// ChatParticipant -> ChatParticipantEntity
  static entity.ChatParticipantEntity _participantToEntity(model.ChatParticipant participant) {
    return entity.ChatParticipantEntity(
      userId: participant.userId,
      name: participant.name,
      photoUrl: participant.photoUrl,
      joinedAt: participant.joinedAt,
      role: participant.role,
      isActive: participant.isActive,
      lastSeen: participant.lastSeen,
      metadata: participant.metadata,
    );
  }

  /// ChatParticipantEntity -> ChatParticipant
  static model.ChatParticipant _participantToModel(entity.ChatParticipantEntity participant) {
    return model.ChatParticipant(
      userId: participant.userId,
      name: participant.name,
      photoUrl: participant.photoUrl,
      joinedAt: participant.joinedAt,
      role: participant.role,
      isActive: participant.isActive,
      lastSeen: participant.lastSeen,
      metadata: participant.metadata,
    );
  }
}

