/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

/** Belirtilen kullanıcı ID'lerinin FCM tokenlarını toplar. */
async function collectFcmTokens(userIds) {
  const tokens = new Set();
  const uniqueIds = [...new Set(userIds)].filter((id) => typeof id === "string" && id.length > 0);

  await Promise.all(uniqueIds.map(async (uid) => {
    const doc = await admin.firestore().collection("users").doc(uid).get();
    if (!doc.exists) return;
    const userData = doc.data();
    if (Array.isArray(userData.fcmTokens)) {
      userData.fcmTokens.forEach((token) => tokens.add(token));
    }
  }));

  return tokens;
}

/** Token listesine push bildirimi gönderir (500'lük parçalar halinde). */
async function sendPushToTokens(tokens, notification, data = {}) {
  const tokenList = Array.from(tokens);
  if (tokenList.length === 0) {
    return 0;
  }

  let successCount = 0;
  for (let i = 0; i < tokenList.length; i += 500) {
    const chunk = tokenList.slice(i, i + 500);
    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk,
      notification,
      data,
    });
    successCount += response.successCount;
  }
  return successCount;
}

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Yeni etkinlik oluşturulduğunda etkinlik sahibinin takipçilerine bildirim gönder
exports.sendNewEventNotification = onDocumentCreated("events/{eventId}", async (event) => {
  const eventData = event.data.data();
  const title = eventData.title || "Yeni Etkinlik";
  const description = (eventData.description || "").substring(0, 60);
  const creatorId = eventData.createdBy;

  if (!creatorId) {
    logger.warn("New event has no createdBy, skipping notification.");
    return null;
  }

  const creatorDoc = await admin.firestore().collection("users").doc(creatorId).get();
  if (!creatorDoc.exists) {
    logger.warn("Event creator not found:", creatorId);
    return null;
  }

  const followers = Array.isArray(creatorDoc.data().followers) ? creatorDoc.data().followers : [];
  const recipientIds = followers.filter((uid) => uid !== creatorId);

  if (recipientIds.length === 0) {
    logger.info("No followers to notify for new event:", event.params.eventId);
    return null;
  }

  const tokens = await collectFcmTokens(recipientIds);
  if (tokens.size === 0) {
    logger.info("No FCM tokens for event followers.");
    return null;
  }

  const creatorName = creatorDoc.data().displayName || "Birisi";
  const sent = await sendPushToTokens(tokens, {
    title: `Yeni Etkinlik: ${title}`,
    body: description || `${creatorName} yeni bir etkinlik oluşturdu`,
  }, {
    type: "new_event",
    eventId: event.params.eventId,
  });

  logger.info("New event notifications sent to followers:", sent);
  return null;
});

// Yeni mesaj oluşturulduğunda alıcılara push bildirimi gönder
exports.sendNewMessageNotification = onDocumentCreated('messages/{messageId}', async (event) => {
  const msg = event.data.data();
  const chatId = msg.chatId;
  const senderId = msg.senderId;
  const text = msg.text || (msg.type === 'voice' ? 'Sesli mesaj' : 'Mesaj');

  if (!chatId || !senderId) {
    logger.warn('Missing chatId or senderId on message, skipping notification.');
    return null;
  }

  // Sohbet katılımcılarını al
  const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
  if (!chatDoc.exists) {
    logger.warn('Chat not found for message:', chatId);
    return null;
  }
  const chat = chatDoc.data();
  const participants = Array.isArray(chat.participants) ? chat.participants : [];
  const recipients = participants.filter((uid) => uid !== senderId);
  if (recipients.length === 0) {
    logger.info('No recipients for message in chat:', chatId);
    return null;
  }

  // Gönderen kullanıcının bilgilerini al
  const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
  if (!senderDoc.exists) {
    logger.warn('Sender not found:', senderId);
    return null;
  }
  const senderData = senderDoc.data();
  const senderName = senderData.displayName || 'Birisi';

  // Alıcıların tokenlarını topla ve takip durumunu kontrol et
  const batches = [];
  const messageRequestBatches = [];
  const tokens = new Set();
  const messageRequestTokens = new Set();
  
  for (const recipientId of recipients) {
    batches.push(
      admin.firestore().collection('users').doc(recipientId).get().then(async (doc) => {
        if (!doc.exists) return;
        
        const recipientData = doc.data();
        if (Array.isArray(recipientData.fcmTokens)) {
          // ✅ Sessize alma kontrolü
          const mutedUntil = chat.mutedUntil && chat.mutedUntil[recipientId] 
            ? chat.mutedUntil[recipientId].toDate() 
            : null;
          
          if (mutedUntil !== null) {
            // Süre dolmuş mu kontrol et
            if (new Date() < mutedUntil) {
              // Hala sessize alınmış, bildirim gönderme
              logger.info(`Chat ${chatId} is muted for user ${recipientId} until ${mutedUntil}`);
              return;
            }
          } else if (chat.mutedBy && chat.mutedBy[recipientId] === true) {
            // Eski sistem: Süresiz sessize alınmış
            logger.info(`Chat ${chatId} is muted (unlimited) for user ${recipientId}`);
            return;
          }
          
          // Karşılıklı takip kontrolü
          const senderFollowing = Array.isArray(senderData.following) ? senderData.following : [];
          const recipientFollowing = Array.isArray(recipientData.following) ? recipientData.following : [];
          
          const isMutualFollow = senderFollowing.includes(recipientId) && recipientFollowing.includes(senderId);
          
          if (isMutualFollow) {
            // Normal mesaj bildirimi
            recipientData.fcmTokens.forEach((t) => tokens.add(t));
          } else {
            // Mesaj isteği bildirimi
            recipientData.fcmTokens.forEach((t) => messageRequestTokens.add(t));
            
            // Mesaj isteği bildirimi oluştur
            await admin.firestore().collection('notifications').add({
              userId: recipientId,
              type: 'message_request',
              relatedUserId: senderId,
              relatedChatId: chatId,
              title: 'Mesaj İsteği',
              body: `${senderName} sana mesaj gönderdi`,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }
      })
    );
  }
  await Promise.all(batches);

  // Normal mesaj bildirimi gönder
  if (tokens.size > 0) {
  const payload = {
    notification: {
      title: chat.name ? `Yeni mesaj • ${chat.name}` : 'Yeni mesaj',
      body: text.length > 80 ? `${text.substring(0, 77)}…` : text,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    data: {
      chatId: chatId,
      messageId: event.params.messageId,
      type: msg.type || 'text',
    },
  };

  const sent = await sendPushToTokens(tokens, payload.notification, payload.data);
  logger.info("Message notifications sent:", sent);
  }

  // Mesaj isteği bildirimi gönder
  if (messageRequestTokens.size > 0) {
    const sent = await sendPushToTokens(messageRequestTokens, {
      title: "Mesaj İsteği",
      body: `${senderName} sana mesaj gönderdi`,
    }, {
      chatId: chatId,
      messageId: event.params.messageId,
      type: "message_request",
    });
    logger.info("Message request notifications sent:", sent);
  }

  return null;
});

// Event katılma isteği geldiğinde event sahibine push bildirimi gönder
exports.sendJoinRequestNotification = onDocumentUpdated("events/{eventId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  const previousPending = Array.isArray(before.pendingRequests) ? before.pendingRequests : [];
  const currentPending = Array.isArray(after.pendingRequests) ? after.pendingRequests : [];
  const newRequests = currentPending.filter((uid) => !previousPending.includes(uid));

  if (newRequests.length === 0) {
    return null;
  }

  const ownerId = after.createdBy;
  if (!ownerId) {
    logger.warn("Event has no owner:", event.params.eventId);
    return null;
  }

  const ownerTokens = await collectFcmTokens([ownerId]);
  const eventTitle = after.title || "Etkinlik";

  for (const requesterId of newRequests) {
    const requesterDoc = await admin.firestore().collection("users").doc(requesterId).get();
    const requesterName = requesterDoc.exists ?
      (requesterDoc.data().displayName || "Birisi") :
      "Birisi";

    const body = `${requesterName} "${eventTitle}" etkinliğine katılmak istiyor`;

    if (ownerTokens.size > 0) {
      await sendPushToTokens(ownerTokens, {
        title: "Katılma İsteği",
        body,
      }, {
        type: "event_join_request",
        eventId: event.params.eventId,
        requesterId,
      });
    }

    await admin.firestore().collection("notifications").add({
      userId: ownerId,
      type: "event_join_request",
      relatedUserId: requesterId,
      relatedEventId: event.params.eventId,
      title: "Katılma İsteği",
      body,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  logger.info("Join request notifications sent for event:", event.params.eventId);
  return null;
});

// Event chat'ine mesaj geldiğinde katılımcılara push bildirimi gönder
exports.sendEventChatNotification = onDocumentCreated('events/{eventId}/comments/{commentId}', async (event) => {
  const comment = event.data.data();
  const eventId = event.params.eventId;
  
  // Sistem mesajlarını atla
  if (comment.type === 'system') {
    return null;
  }

  const senderId = comment.userId;
  const senderName = comment.userName || 'Birisi';
  const text = comment.text || 'Yeni mesaj';

  // Event bilgilerini al
  const eventDoc = await admin.firestore().collection('events').doc(eventId).get();
  if (!eventDoc.exists) {
    logger.warn('Event not found for comment:', eventId);
    return null;
  }

  const eventData = eventDoc.data();
  const eventTitle = eventData.title || 'Etkinlik';
  
  // Tüm katılımcıları al (participants + approvedParticipants + createdBy)
  const participants = new Set([
    ...(eventData.participants || []),
    ...(eventData.approvedParticipants || []),
    eventData.createdBy,
  ]);
  
  // Göndereni çıkar
  participants.delete(senderId);

  if (participants.size === 0) {
    return null;
  }

  // Katılımcıların tokenlarını topla
  const tokens = new Set();
  for (const participantId of participants) {
    const userDoc = await admin.firestore().collection('users').doc(participantId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (Array.isArray(userData.fcmTokens)) {
        userData.fcmTokens.forEach(t => tokens.add(t));
      }
    }
  }

  if (tokens.size === 0) {
    logger.info('No tokens found for event chat notification');
    return null;
  }

  // Bildirim içeriği
  const payload = {
    notification: {
      title: `${eventTitle} - Yeni Mesaj`,
      body: `${senderName}: ${text.substring(0, 60)}`,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    data: {
      type: 'event_chat',
      eventId: eventId,
      commentId: event.params.commentId,
    },
  };

  const sent = await sendPushToTokens(tokens, payload.notification, payload.data);
  logger.info("Event chat notifications sent:", sent);
  return null;
});

// Takip bildirimi oluşturulduğunda push bildirimi gönder
exports.sendFollowNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const notification = event.data.data();
  
  // Takip isteği, takip isteği kabul edildi ve mesaj isteği bildirimleri için push gönder
  if (!['follow_request', 'follow_request_accepted', 'message_request'].includes(notification.type) || !notification.userId) {
    return null;
  }

  // Bildirimi alan kullanıcının FCM tokenlarını al
  const userDoc = await admin.firestore().collection('users').doc(notification.userId).get();
  if (!userDoc.exists) {
    logger.warn('User not found for notification:', notification.userId);
    return null;
  }

  const userData = userDoc.data();
  const tokens = Array.isArray(userData.fcmTokens) ? userData.fcmTokens : [];
  
  if (tokens.length === 0) {
    logger.info('No FCM tokens for user:', notification.userId);
    return null;
  }

  // İlgili kullanıcının bilgilerini al
  let relatedUserName = 'Birisi';
  if (notification.relatedUserId) {
    const relatedUserDoc = await admin.firestore().collection('users').doc(notification.relatedUserId).get();
    if (relatedUserDoc.exists) {
      relatedUserName = relatedUserDoc.data().displayName || relatedUserName;
    }
  }

  // Bildirim tipine göre içerik hazırla
  let title = '';
  let body = '';
  
  if (notification.type === 'follow_request') {
    title = 'Takip İsteği';
    body = `${relatedUserName} sana takip isteği gönderdi`;
  } else if (notification.type === 'follow_request_accepted') {
    title = 'Takip İsteği Kabul Edildi';
    body = `${relatedUserName} takip isteğini kabul etti`;
  } else if (notification.type === 'message_request') {
    title = 'Mesaj İsteği';
    body = `${relatedUserName} sana mesaj gönderdi`;
  }

  // Bildirim içeriği
  const payload = {
    notification: {
      title: title,
      body: body,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    data: {
      type: notification.type,
      notificationId: event.params.notificationId,
      relatedUserId: notification.relatedUserId || '',
      relatedChatId: notification.relatedChatId || '',
    },
  };

  const sent = await sendPushToTokens(new Set(tokens), payload.notification, payload.data);
  logger.info(`${notification.type} notifications sent:`, sent);
  return null;
});

/** Firestore sorgusundaki belgeleri 500'lük partiler halinde siler. */
async function deleteDocumentsByQuery(query) {
  const snapshot = await query.limit(500).get();
  if (snapshot.empty) {
    return;
  }

  const batch = admin.firestore().batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();

  if (snapshot.size === 500) {
    await deleteDocumentsByQuery(query);
  }
}

/** Kullanıcıyı diğer kullanıcıların sosyal listelerinden çıkarır. */
async function removeUserFromSocialLists(db, uid, field) {
  const snapshot = await db.collection("users").where(field, "array-contains", uid).get();
  if (snapshot.empty) {
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {[field]: admin.firestore.FieldValue.arrayRemove(uid)});
  });
  await batch.commit();

  if (snapshot.size === 500) {
    await removeUserFromSocialLists(db, uid, field);
  }
}

/** Kullanıcı hesabını ve ilişkili verileri kalıcı olarak siler. */
exports.deleteUserAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Oturum açık olmalı");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  logger.info("deleteUserAccount started", {uid});

  try {
    await deleteDocumentsByQuery(
        db.collection("notifications").where("userId", "==", uid),
    );

    const chatsSnapshot = await db.collection("chats")
        .where("participants", "array-contains", uid)
        .get();
    for (const chatDoc of chatsSnapshot.docs) {
      await chatDoc.ref.update({
        participants: admin.firestore.FieldValue.arrayRemove(uid),
        admins: admin.firestore.FieldValue.arrayRemove(uid),
        [`participantDetails.${uid}`]: admin.firestore.FieldValue.delete(),
      });
    }

    const eventsSnapshot = await db.collection("events").where("createdBy", "==", uid).get();
    for (const eventDoc of eventsSnapshot.docs) {
      await deleteDocumentsByQuery(eventDoc.ref.collection("messages"));
      await deleteDocumentsByQuery(eventDoc.ref.collection("comments"));
      await eventDoc.ref.delete();
    }

    const participantEvents = await db.collection("events")
        .where("participants", "array-contains", uid)
        .get();
    for (const eventDoc of participantEvents.docs) {
      await eventDoc.ref.update({
        participants: admin.firestore.FieldValue.arrayRemove(uid),
        approvedParticipants: admin.firestore.FieldValue.arrayRemove(uid),
        pendingRequests: admin.firestore.FieldValue.arrayRemove(uid),
      });
    }

    await removeUserFromSocialLists(db, uid, "followers");
    await removeUserFromSocialLists(db, uid, "following");
    await removeUserFromSocialLists(db, uid, "pendingFollowRequests");
    await removeUserFromSocialLists(db, uid, "sentFollowRequests");

    await deleteDocumentsByQuery(
        db.collection("messages").where("senderId", "==", uid),
    );

    await db.collection("users").doc(uid).delete();

    try {
      const bucket = admin.storage().bucket();
      const [files] = await bucket.getFiles({prefix: `profile_photos/${uid}/`});
      await Promise.all(files.map((file) => file.delete()));
    } catch (storageError) {
      logger.warn("Profile storage cleanup partial", storageError);
    }

    await admin.auth().deleteUser(uid);
    logger.info("deleteUserAccount completed", {uid});
    return {success: true};
  } catch (error) {
    logger.error("deleteUserAccount failed", {uid, error});
    throw new HttpsError("internal", "Hesap silinirken bir hata oluştu");
  }
});