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
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');
admin.initializeApp();

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

// Yeni etkinlik oluşturulduğunda push bildirimi gönder
exports.sendNewEventNotification = onDocumentCreated('events/{eventId}', async (event) => {
  const eventData = event.data.data();
  const title = eventData.title || 'Yeni Etkinlik';
  const description = eventData.description || '';

  // Tüm kullanıcıların FCM tokenlarını topla
  const usersSnapshot = await admin.firestore().collection('users').get();
  let tokens = [];
  usersSnapshot.forEach(doc => {
    const userData = doc.data();
    if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
      tokens = tokens.concat(userData.fcmTokens);
    }
  });
  // Token yoksa çık
  if (tokens.length === 0) {
    console.log('No tokens found.');
    return null;
  }

  // Bildirim içeriği
  const payload = {
    notification: {
      title: `Yeni Etkinlik: ${title}`,
      body: description.substring(0, 60),
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    data: {
      eventId: event.params.eventId,
    },
  };

  // Bildirimleri gönder
  const response = await admin.messaging().sendToDevice(tokens, payload);
  console.log('Notifications sent:', response.successCount);
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
  const senderName = senderData?.displayName || 'Birisi';

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

    const response = await admin.messaging().sendToDevice(Array.from(tokens), payload);
    logger.info('Message notifications sent:', response.successCount);
  }

  // Mesaj isteği bildirimi gönder
  if (messageRequestTokens.size > 0) {
    const payload = {
      notification: {
        title: 'Mesaj İsteği',
        body: `${senderName} sana mesaj gönderdi`,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        chatId: chatId,
        messageId: event.params.messageId,
        type: 'message_request',
      },
    };

    const response = await admin.messaging().sendToDevice(Array.from(messageRequestTokens), payload);
    logger.info('Message request notifications sent:', response.successCount);
  }

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

  const response = await admin.messaging().sendToDevice(tokens, payload);
  logger.info(`${notification.type} notifications sent:`, response.successCount);
  return null;
});