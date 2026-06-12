/// User Entity
/// 
/// Clean Architecture Domain Layer
/// Pure Dart entity, Firebase bağımlılığı yok
class UserEntity {
  final String uid;
  final String email;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? photoUrl;
  final List<String> followers;
  final List<String> following;
  final List<String> fcmTokens;
  final List<String> pendingFollowRequests;
  final List<String> sentFollowRequests;
  // Gizlilik ayarları
  final bool isPrivate;
  final bool showLocation;
  final bool showOnlineStatus;
  // Engellenen kullanıcılar
  final List<String> blockedUsers;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.username,
    this.bio,
    this.photoUrl,
    this.followers = const [],
    this.following = const [],
    this.fcmTokens = const [],
    this.pendingFollowRequests = const [],
    this.sentFollowRequests = const [],
    this.isPrivate = false,
    this.showLocation = true,
    this.showOnlineStatus = true,
    this.blockedUsers = const [],
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? bio,
    String? photoUrl,
    List<String>? followers,
    List<String>? following,
    List<String>? fcmTokens,
    List<String>? pendingFollowRequests,
    List<String>? sentFollowRequests,
    bool? isPrivate,
    bool? showLocation,
    bool? showOnlineStatus,
    List<String>? blockedUsers,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      pendingFollowRequests: pendingFollowRequests ?? this.pendingFollowRequests,
      sentFollowRequests: sentFollowRequests ?? this.sentFollowRequests,
      isPrivate: isPrivate ?? this.isPrivate,
      showLocation: showLocation ?? this.showLocation,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserEntity(uid: $uid, email: $email, displayName: $displayName)';
}

