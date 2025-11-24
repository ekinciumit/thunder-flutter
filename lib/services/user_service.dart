import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _notificationsRef = FirebaseFirestore.instance.collection('notifications');

  /// Takip isteği gönder
  Future<void> sendFollowRequest(String currentUserId, String targetUserId) async {
    // Gönderen kullanıcının bilgilerini al
    final currentUserDoc = await _usersRef.doc(currentUserId).get();
    final currentUserName = currentUserDoc.data()?['displayName'] ?? 'Birisi';

    // İstek gönderen kullanıcının sentFollowRequests listesine ekle
    await _usersRef.doc(currentUserId).update({
      'sentFollowRequests': FieldValue.arrayUnion([targetUserId])
    });

    // İstek alan kullanıcının pendingFollowRequests listesine ekle
    await _usersRef.doc(targetUserId).update({
      'pendingFollowRequests': FieldValue.arrayUnion([currentUserId])
    });

    // Bildirim oluştur
    await _notificationsRef.add({
      'userId': targetUserId,
      'type': 'follow_request',
      'relatedUserId': currentUserId,
      'title': 'Takip İsteği',
      'body': '$currentUserName sana takip isteği gönderdi',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Takip isteğini kabul et
  Future<void> acceptFollowRequest(String currentUserId, String requesterUserId) async {
    // Karşılıklı takip oluştur
    await _usersRef.doc(currentUserId).update({
      'following': FieldValue.arrayUnion([requesterUserId]),
      'pendingFollowRequests': FieldValue.arrayRemove([requesterUserId])
    });
    await _usersRef.doc(requesterUserId).update({
      'followers': FieldValue.arrayUnion([currentUserId]),
      'sentFollowRequests': FieldValue.arrayRemove([currentUserId])
    });

    // İstek gönderen kullanıcının bilgilerini al
    final requesterUserDoc = await _usersRef.doc(requesterUserId).get();
    final requesterUserName = requesterUserDoc.data()?['displayName'] ?? 'Birisi';

    // İstek gönderen kullanıcıya bildirim gönder
    await _notificationsRef.add({
      'userId': requesterUserId,
      'type': 'follow_request_accepted',
      'relatedUserId': currentUserId,
      'title': 'Takip İsteği Kabul Edildi',
      'body': '$requesterUserName takip isteğini kabul etti',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Takip isteğini reddet
  Future<void> rejectFollowRequest(String currentUserId, String requesterUserId) async {
    // İstekleri kaldır
    await _usersRef.doc(currentUserId).update({
      'pendingFollowRequests': FieldValue.arrayRemove([requesterUserId])
    });
    await _usersRef.doc(requesterUserId).update({
      'sentFollowRequests': FieldValue.arrayRemove([currentUserId])
    });
  }

  /// Takip isteğini iptal et (gönderen tarafından)
  Future<void> cancelFollowRequest(String currentUserId, String targetUserId) async {
    // İstekleri kaldır
    await _usersRef.doc(currentUserId).update({
      'sentFollowRequests': FieldValue.arrayRemove([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'pendingFollowRequests': FieldValue.arrayRemove([currentUserId])
    });
  }

  /// Takibi bırak (karşılıklı takip varsa)
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  }

  /// Bildirimleri okundu olarak işaretle
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final notifications = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
} 