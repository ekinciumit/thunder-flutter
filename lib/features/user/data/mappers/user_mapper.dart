import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// User Entity <-> UserModel (DTO) Mapper
/// 
/// Clean Architecture Data Layer
/// Domain entity ile data DTO arasında dönüşüm yapar
class UserMapper {
  /// UserModel (DTO) -> UserEntity
  static UserEntity toEntity(UserModel model) {
    return UserEntity(
      uid: model.uid,
      email: model.email,
      displayName: model.displayName,
      username: model.username,
      bio: model.bio,
      photoUrl: model.photoUrl,
      followers: model.followers,
      following: model.following,
      fcmTokens: model.fcmTokens,
      pendingFollowRequests: model.pendingFollowRequests,
      sentFollowRequests: model.sentFollowRequests,
      isPrivate: model.isPrivate,
      showLocation: model.showLocation,
      showOnlineStatus: model.showOnlineStatus,
      blockedUsers: model.blockedUsers,
    );
  }

  /// UserEntity -> UserModel (DTO)
  static UserModel toModel(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      username: entity.username,
      bio: entity.bio,
      photoUrl: entity.photoUrl,
      followers: entity.followers,
      following: entity.following,
      fcmTokens: entity.fcmTokens,
      pendingFollowRequests: entity.pendingFollowRequests,
      sentFollowRequests: entity.sentFollowRequests,
      isPrivate: entity.isPrivate,
      showLocation: entity.showLocation,
      showOnlineStatus: entity.showOnlineStatus,
      blockedUsers: entity.blockedUsers,
    );
  }

  /// List<UserModel> -> List<UserEntity>
  static List<UserEntity> toEntityList(List<UserModel> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// List<UserEntity> -> List<UserModel>
  static List<UserModel> toModelList(List<UserEntity> entities) {
    return entities.map((entity) => toModel(entity)).toList();
  }
}

