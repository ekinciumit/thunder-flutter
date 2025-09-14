class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? photoUrl;
  final List<String> followers;
  final List<String> following;
  final List<String> fcmTokens; // Yeni alan

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.username,
    this.bio,
    this.photoUrl,
    this.followers = const [],
    this.following = const [],
    this.fcmTokens = const [], // Yeni alan
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
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []), // Yeni alan
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
      'fcmTokens': fcmTokens, // Yeni alan
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
    List<String>? fcmTokens, // Yeni alan
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
      fcmTokens: fcmTokens ?? this.fcmTokens, // Yeni alan
    );
  }
} 