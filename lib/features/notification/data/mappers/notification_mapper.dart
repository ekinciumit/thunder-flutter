import '../../domain/entities/notification_entity.dart' as entity;
import '../models/notification_model.dart' as model;

/// Notification Entity <-> NotificationModel (DTO) Mapper
/// 
/// Clean Architecture Data Layer
/// Domain entity ile data DTO arasında dönüşüm yapar
class NotificationMapper {
  /// NotificationModel (DTO) -> NotificationEntity
  static entity.NotificationEntity toEntity(model.NotificationModel model) {
    return entity.NotificationEntity(
      id: model.id,
      userId: model.userId,
      type: model.type,
      relatedUserId: model.relatedUserId,
      relatedEventId: model.relatedEventId,
      relatedChatId: model.relatedChatId,
      title: model.title,
      body: model.body,
      isRead: model.isRead,
      createdAt: model.createdAt,
      metadata: model.metadata,
      actionUrl: model.actionUrl,
      dedupKey: model.dedupKey,
      imageUrl: model.imageUrl,
      actionLabel: model.actionLabel,
      groupCount: model.groupCount,
      groupedUserIds: model.groupedUserIds,
    );
  }

  /// NotificationEntity -> NotificationModel (DTO)
  static model.NotificationModel toModel(entity.NotificationEntity entity) {
    return model.NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      relatedUserId: entity.relatedUserId,
      relatedEventId: entity.relatedEventId,
      relatedChatId: entity.relatedChatId,
      title: entity.title,
      body: entity.body,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      metadata: entity.metadata,
      actionUrl: entity.actionUrl,
      dedupKey: entity.dedupKey,
      imageUrl: entity.imageUrl,
      actionLabel: entity.actionLabel,
      groupCount: entity.groupCount,
      groupedUserIds: entity.groupedUserIds,
    );
  }

  /// `List<NotificationModel>` -> `List<NotificationEntity>`
  static List<entity.NotificationEntity> toEntityList(List<model.NotificationModel> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// `List<NotificationEntity>` -> `List<NotificationModel>`
  static List<model.NotificationModel> toModelList(List<entity.NotificationEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }

  /// Map (from Firestore) -> NotificationEntity
  /// UI katmanından data/models import'unu önlemek için
  static entity.NotificationEntity fromMap(Map<String, dynamic> data, String id) {
    final notificationModel = model.NotificationModel.fromMap(data, id);
    return toEntity(notificationModel);
  }
}

