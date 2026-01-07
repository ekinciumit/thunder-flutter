import '../../domain/entities/event_entity.dart';
import '../models/event_model.dart';

/// Event Entity <-> EventModel (DTO) Mapper
/// 
/// Clean Architecture Data Layer
/// Domain entity ile data DTO arasında dönüşüm yapar
class EventMapper {
  /// EventModel (DTO) -> EventEntity
  static EventEntity toEntity(EventModel model) {
    return EventEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      location: model.locationEntity, // GeoPoint -> LocationEntity
      address: model.address,
      datetime: model.datetime,
      quota: model.quota,
      createdBy: model.createdBy,
      participants: model.participants,
      coverPhotoUrl: model.coverPhotoUrl,
      category: model.category,
      pendingRequests: model.pendingRequests,
      approvedParticipants: model.approvedParticipants,
      status: model.status,
      cancelledAt: model.cancelledAt,
      cancellationReason: model.cancellationReason,
    );
  }

  /// EventEntity -> EventModel (DTO)
  static EventModel toModel(EventEntity entity) {
    return EventModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      location: EventModel.locationEntityToGeoPoint(entity.location), // LocationEntity -> GeoPoint
      address: entity.address,
      datetime: entity.datetime,
      quota: entity.quota,
      createdBy: entity.createdBy,
      participants: entity.participants,
      coverPhotoUrl: entity.coverPhotoUrl,
      category: entity.category,
      pendingRequests: entity.pendingRequests,
      approvedParticipants: entity.approvedParticipants,
      status: entity.status,
      cancelledAt: entity.cancelledAt,
      cancellationReason: entity.cancellationReason,
    );
  }

  /// `List<EventModel>` -> `List<EventEntity>`
  static List<EventEntity> toEntityList(List<EventModel> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// `List<EventEntity>` -> `List<EventModel>`
  static List<EventModel> toModelList(List<EventEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}

