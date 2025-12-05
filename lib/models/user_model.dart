class UserModel {
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

  UserModel({
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

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      username: map['username'],
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      pendingFollowRequests: List<String>.from(map['pendingFollowRequests'] ?? []),
      sentFollowRequests: List<String>.from(map['sentFollowRequests'] ?? []),
      isPrivate: map['isPrivate'] ?? false,
      showLocation: map['showLocation'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'photoUrl': photoUrl,
      'followers': followers,
      'following': following,
      'fcmTokens': fcmTokens,
      'pendingFollowRequests': pendingFollowRequests,
      'sentFollowRequests': sentFollowRequests,
      'isPrivate': isPrivate,
      'showLocation': showLocation,
      'showOnlineStatus': showOnlineStatus,
      'blockedUsers': blockedUsers,
    };
  }

  UserModel copyWith({
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
    return UserModel(
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
}
