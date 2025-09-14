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
