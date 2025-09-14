import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _usersRef = FirebaseFirestore.instance.collection('users');

  /// Takip et
  Future<void> followUser(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'following': FieldValue.arrayUnion([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId])
    });
  }

  /// Takibi bırak
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  }
} 