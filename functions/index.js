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

  // Alıcıların tokenlarını topla
  const batches = [];
  const tokens = new Set();
  // Firestore where-in 10 limitine takılmamak için tek tek çekiyoruz (katılımcı sayısı düşük varsayım)
  for (const uid of recipients) {
    batches.push(
      admin.firestore().collection('users').doc(uid).get().then((doc) => {
        if (doc.exists) {
          const data = doc.data();
          if (Array.isArray(data.fcmTokens)) {
            data.fcmTokens.forEach((t) => tokens.add(t));
          }
        }
      })
    );
  }
  await Promise.all(batches);
  if (tokens.size === 0) {
    logger.info('No FCM tokens for recipients.');
    return null;
  }

  // Bildirim içeriği
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
  return null;
});