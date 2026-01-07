import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _notificationsRef = FirebaseFirestore.instance.collection('notifications');

  Future<void> sendFollowRequest(String currentUserId, String targetUserId) async {
    final currentUserDoc = await _usersRef.doc(currentUserId).get();
    final currentUserName = currentUserDoc.data()?['displayName'] ?? 'Birisi';

    await _usersRef.doc(currentUserId).update({
      'sentFollowRequests': FieldValue.arrayUnion([targetUserId])
    });

    await _usersRef.doc(targetUserId).update({
      'pendingFollowRequests': FieldValue.arrayUnion([currentUserId])
    });

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

  Future<void> acceptFollowRequest(String currentUserId, String requesterUserId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    batch.update(_usersRef.doc(requesterUserId), {
      'following': FieldValue.arrayUnion([currentUserId]),
      'sentFollowRequests': FieldValue.arrayRemove([currentUserId]),
    });
    
    batch.update(_usersRef.doc(currentUserId), {
      'followers': FieldValue.arrayUnion([requesterUserId]),
      'pendingFollowRequests': FieldValue.arrayRemove([requesterUserId]),
    });
    
    await batch.commit();

    final currentUserDoc = await _usersRef.doc(currentUserId).get();
    final currentUserName = currentUserDoc.data()?['displayName'] ?? 'Birisi';

    await _notificationsRef.add({
      'userId': requesterUserId,
      'type': 'follow_request_accepted',
      'relatedUserId': currentUserId,
      'title': 'Takip İsteği Kabul Edildi ✓',
      'body': '$currentUserName takip isteğini kabul etti. Artık onu takip ediyorsun!',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectFollowRequest(String currentUserId, String requesterUserId) async {
    await _usersRef.doc(currentUserId).update({
      'pendingFollowRequests': FieldValue.arrayRemove([requesterUserId])
    });
    await _usersRef.doc(requesterUserId).update({
      'sentFollowRequests': FieldValue.arrayRemove([currentUserId])
    });
  }

  Future<void> cancelFollowRequest(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'sentFollowRequests': FieldValue.arrayRemove([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'pendingFollowRequests': FieldValue.arrayRemove([currentUserId])
    });
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'following': FieldValue.arrayRemove([targetUserId])
    });
    await _usersRef.doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
    });
  }

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

  // Privacy settings
  
  Future<void> updatePrivacySettings({
    required String userId,
    bool? isPrivate,
    bool? showLocation,
    bool? showOnlineStatus,
  }) async {
    final updates = <String, dynamic>{};
    
    if (isPrivate != null) updates['isPrivate'] = isPrivate;
    if (showLocation != null) updates['showLocation'] = showLocation;
    if (showOnlineStatus != null) updates['showOnlineStatus'] = showOnlineStatus;
    
    if (updates.isNotEmpty) {
      await _usersRef.doc(userId).update(updates);
    }
  }

  Future<void> setPrivateAccount(String userId, bool isPrivate) async {
    await _usersRef.doc(userId).update({'isPrivate': isPrivate});
  }

  Future<void> setShowLocation(String userId, bool showLocation) async {
    await _usersRef.doc(userId).update({'showLocation': showLocation});
  }

  Future<void> setShowOnlineStatus(String userId, bool showOnlineStatus) async {
    await _usersRef.doc(userId).update({'showOnlineStatus': showOnlineStatus});
  }

  // Block operations
  
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    // Engellenen kullanıcılar listesine ekle
    await _usersRef.doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId])
    });

    // Takip ilişkilerini kaldır
    await _usersRef.doc(currentUserId).update({
      'followers': FieldValue.arrayRemove([targetUserId]),
      'following': FieldValue.arrayRemove([targetUserId]),
      'pendingFollowRequests': FieldValue.arrayRemove([targetUserId]),
      'sentFollowRequests': FieldValue.arrayRemove([targetUserId]),
    });

    await _usersRef.doc(targetUserId).update({
      'followers': FieldValue.arrayRemove([currentUserId]),
      'following': FieldValue.arrayRemove([currentUserId]),
      'pendingFollowRequests': FieldValue.arrayRemove([currentUserId]),
      'sentFollowRequests': FieldValue.arrayRemove([currentUserId]),
    });
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _usersRef.doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId])
    });
  }

  Future<List<String>> getBlockedUsers(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    final data = doc.data();
    if (data != null && data['blockedUsers'] != null) {
      return List<String>.from(data['blockedUsers']);
    }
    return [];
  }

  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    final doc = await _usersRef.doc(currentUserId).get();
    final data = doc.data();
    if (data != null && data['blockedUsers'] != null) {
      return List<String>.from(data['blockedUsers']).contains(targetUserId);
    }
    return false;
  }

  // Notifications
  
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedUserId,
    String? relatedEventId,
    String? relatedChatId,
    Map<String, dynamic>? metadata,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'relatedUserId': relatedUserId,
      'relatedEventId': relatedEventId,
      'relatedChatId': relatedChatId,
      'metadata': metadata,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEventInvitation({
    required String targetUserId,
    required String eventId,
    required String eventTitle,
    required String inviterName,
  }) async {
    await sendNotification(
      userId: targetUserId,
      type: 'event_invitation',
      title: 'Etkinliğe Davet',
      body: '$inviterName seni "$eventTitle" etkinliğine davet etti',
      relatedEventId: eventId,
    );
  }

  Future<void> sendEventReminder({
    required String targetUserId,
    required String eventId,
    required String eventTitle,
    required String timeInfo,
  }) async {
    await sendNotification(
      userId: targetUserId,
      type: 'event_reminder',
      title: 'Etkinlik Hatırlatması ⏰',
      body: '"$eventTitle" $timeInfo başlayacak',
      relatedEventId: eventId,
    );
  }

  Future<void> notifyEventJoinRequest({
    required String eventOwnerId,
    required String eventId,
    required String eventTitle,
    required String requesterName,
    required String requesterId,
  }) async {
    await sendNotification(
      userId: eventOwnerId,
      type: 'event_join_request',
      title: 'Katılma İsteği',
      body: '$requesterName "$eventTitle" etkinliğine katılmak istiyor',
      relatedEventId: eventId,
      relatedUserId: requesterId,
    );
  }

  Future<void> notifyEventJoinApproved({
    required String participantId,
    required String eventId,
    required String eventTitle,
  }) async {
    await sendNotification(
      userId: participantId,
      type: 'event_join_approved',
      title: 'Katılımın Onaylandı! 🎉',
      body: '"$eventTitle" etkinliğine katılımın onaylandı',
      relatedEventId: eventId,
    );
  }

  Future<void> notifyEventJoinRejected({
    required String participantId,
    required String eventId,
    required String eventTitle,
  }) async {
    await sendNotification(
      userId: participantId,
      type: 'event_join_rejected',
      title: 'Katılım Reddedildi',
      body: '"$eventTitle" etkinliğine katılım isteğin reddedildi',
      relatedEventId: eventId,
    );
  }

  Future<void> sendMessageNotification({
    required String targetUserId,
    required String chatId,
    required String senderName,
    required String messagePreview,
  }) async {
    // Önce aynı chat için son 5 dakikada bildirim var mı kontrol et
    // (spam engelleme)
    final recentNotifications = await _notificationsRef
        .where('userId', isEqualTo: targetUserId)
        .where('type', isEqualTo: 'message')
        .where('relatedChatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (recentNotifications.docs.isNotEmpty) {
      final lastNotification = recentNotifications.docs.first;
      final lastTime = (lastNotification.data()['createdAt'] as Timestamp?)?.toDate();
      if (lastTime != null) {
        final difference = DateTime.now().difference(lastTime);
        if (difference.inMinutes < 5) {
          // Son 5 dakikada bildirim gönderilmiş, yeni bildirim gönderme
          // Sadece mevcut bildirimi güncelle
          await lastNotification.reference.update({
            'body': '$senderName: $messagePreview',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
          return;
        }
      }
    }

    await sendNotification(
      userId: targetUserId,
      type: 'message',
      title: 'Yeni Mesaj',
      body: '$senderName: $messagePreview',
      relatedChatId: chatId,
    );
  }

  Future<void> cleanupFollowRequestNotification(String userId, String relatedUserId) async {
    final notifications = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'follow_request')
        .where('relatedUserId', isEqualTo: relatedUserId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotificationsByType(String userId, String type) async {
    final notifications = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final result = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();
    return result.count ?? 0;
  }

  Stream<int> getUnreadNotificationCountStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Bildirimleri stream olarak getir
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
                  final data = doc.data();
                  return {
                    ...data,
                    'id': doc.id,
                  };
                })
            .toList());
  }

  // Advanced notifications with dedup
  
  Future<void> sendNotificationWithDedup({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String dedupKey,
    int dedupWindowMinutes = 60,
    String? relatedUserId,
    String? relatedEventId,
    String? relatedChatId,
    String? imageUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
  }) async {
    // Aynı dedupKey ile son X dakikada bildirim var mı?
    final existingNotifications = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('dedupKey', isEqualTo: dedupKey)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (existingNotifications.docs.isNotEmpty) {
      final lastNotification = existingNotifications.docs.first;
      final lastTime = (lastNotification.data()['createdAt'] as Timestamp?)?.toDate();
      
      if (lastTime != null) {
        final difference = DateTime.now().difference(lastTime);
        if (difference.inMinutes < dedupWindowMinutes) {
          // Mevcut bildirimi güncelle
          await lastNotification.reference.update({
            'title': title,
            'body': body,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
            if (imageUrl != null) 'imageUrl': imageUrl,
            if (actionLabel != null) 'actionLabel': actionLabel,
          });
          return;
        }
      }
    }

    // Yeni bildirim oluştur
    await _notificationsRef.add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'dedupKey': dedupKey,
      'relatedUserId': relatedUserId,
      'relatedEventId': relatedEventId,
      'relatedChatId': relatedChatId,
      'imageUrl': imageUrl,
      'actionLabel': actionLabel,
      'metadata': metadata,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendGroupedFollowerNotification({
    required String userId,
    required List<String> followerIds,
    required List<String> followerNames,
  }) async {
    if (followerIds.isEmpty) return;

    final count = followerIds.length;
    String body;
    
    if (count == 1) {
      body = '${followerNames[0]} seni takip etmeye başladı';
    } else if (count == 2) {
      body = '${followerNames[0]} ve ${followerNames[1]} seni takip etmeye başladı';
    } else {
      body = '${followerNames[0]}, ${followerNames[1]} ve ${count - 2} diğer kişi seni takip etti';
    }

    await _notificationsRef.add({
      'userId': userId,
      'type': 'new_followers',
      'title': 'Yeni Takipçiler 👥',
      'body': body,
      'groupCount': count,
      'groupedUserIds': followerIds,
      'relatedUserId': followerIds.first,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendEventReminderWithDedup({
    required String userId,
    required String eventId,
    required String eventTitle,
    required String reminderType, // '24h', '2h', '30m'
    String? eventImageUrl,
  }) async {
    String timeText;
    String type;
    
    switch (reminderType) {
      case '24h':
        timeText = 'yarın';
        type = 'event_reminder_24h';
        break;
      case '2h':
        timeText = '2 saat sonra';
        type = 'event_reminder_2h';
        break;
      case '30m':
        timeText = '30 dakika sonra';
        type = 'event_check_in';
        break;
      default:
        timeText = 'yakında';
        type = 'event_reminder_24h';
    }

    await sendNotificationWithDedup(
      userId: userId,
      type: type,
      title: 'Etkinlik Hatırlatması ⏰',
      body: '"$eventTitle" $timeText başlayacak',
      dedupKey: 'EVENT_REMINDER:$eventId:$reminderType',
      dedupWindowMinutes: 60 * 24, // 24 saat (aynı hatırlatma tekrar gönderilmesin)
      relatedEventId: eventId,
      imageUrl: eventImageUrl,
      actionLabel: 'Detayları Gör',
    );
  }

  Future<void> sendCriticalNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedEventId,
    String? actionLabel,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'relatedEventId': relatedEventId,
      'actionLabel': actionLabel,
      'isRead': false,
      'isCritical': true, // FCM'de yüksek öncelik için kullanılabilir
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> notifyEventCancelled({
    required List<String> participantIds,
    required String eventId,
    required String eventTitle,
    String? reason,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final participantId in participantIds) {
      final docRef = _notificationsRef.doc();
      batch.set(docRef, {
        'userId': participantId,
        'type': 'event_cancelled',
        'title': 'Etkinlik İptal Edildi ⚠️',
        'body': reason != null 
            ? '"$eventTitle" iptal edildi. Sebep: $reason'
            : '"$eventTitle" iptal edildi.',
        'relatedEventId': eventId,
        'actionLabel': 'Detayları Gör',
        'isRead': false,
        'isCritical': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  Future<void> notifyEventUpdated({
    required List<String> participantIds,
    required String eventId,
    required String eventTitle,
    required String changeDescription, // "Saat 19:00'dan 20:00'a değişti"
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final participantId in participantIds) {
      final docRef = _notificationsRef.doc();
      batch.set(docRef, {
        'userId': participantId,
        'type': 'event_updated',
        'title': 'Etkinlik Güncellendi 📝',
        'body': '"$eventTitle": $changeDescription',
        'relatedEventId': eventId,
        'actionLabel': 'Değişiklikleri Gör',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  Future<void> sendWeeklyDigest({
    required String userId,
    required int upcomingEventCount,
    required int newFollowerCount,
    required int unreadMessageCount,
  }) async {
    if (upcomingEventCount == 0 && newFollowerCount == 0 && unreadMessageCount == 0) {
      return; // Boş özet gönderme
    }

    final parts = <String>[];
    if (upcomingEventCount > 0) {
      parts.add('$upcomingEventCount yaklaşan etkinlik');
    }
    if (newFollowerCount > 0) {
      parts.add('$newFollowerCount yeni takipçi');
    }
    if (unreadMessageCount > 0) {
      parts.add('$unreadMessageCount okunmamış mesaj');
    }

    await sendNotificationWithDedup(
      userId: userId,
      type: 'weekly_digest',
      title: 'Haftalık Özet 📊',
      body: 'Bu hafta: ${parts.join(", ")}',
      dedupKey: 'WEEKLY_DIGEST:${DateTime.now().year}:${_getWeekNumber(DateTime.now())}',
      dedupWindowMinutes: 60 * 24 * 7, // 1 hafta
    );
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return ((days + firstDayOfYear.weekday - 1) / 7).ceil();
  }
} 