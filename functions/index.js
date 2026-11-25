const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const logger = require('firebase-functions/logger');

const admin = require('firebase-admin');


initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ============================================================
// 🔥 CONFIGURATION
// ============================================================

const NOTIFICATION_CONFIG = {
  android: {
    priority: 'high',
    notification: {
      channelId: 'high_importance_channel',
      icon: '@mipmap/ic_launcher',
      color: '#C5A059',
      sound: 'alert_sound',
      defaultSound: false
    }
  },
  apns: {
    payload: {
      aps: {
        sound: 'alert_sound.mp3',
        badge: 1,
        'content-available': 1
      }
    },
    headers: {
      'apns-priority': '10'
    }
  }
};

// ============================================================
// 🔥 BOOKING NOTIFICATIONS
// ============================================================

exports.onBookingCreated = onDocumentCreated('bookings/{bookingId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.log('No data associated with the event');
    return;
  }

  const booking = snapshot.data();
  const bookingId = event.params.bookingId;

  logger.log(`📅 New booking created: ${bookingId}`);

  try {
    const notifications = [];

    if (booking.customerId) {
      notifications.push(
        sendPushNotification(
          booking.customerId,
          '📅 Booking Placed Successfully',
          `Your booking #${booking.bookingNumber} for ${booking.serviceName} has been placed. We will confirm it shortly.`,
          'booking',
          { bookingId, bookingNumber: booking.bookingNumber }
        )
      );
    }

    if (booking.branch) {
      notifications.push(
        sendToBranch(
          booking.branch,
          '📅 New Booking Received',
          `${booking.customerName} booked ${booking.serviceName} at ${booking.bookingTime || booking.time} on ${booking.bookingDate || booking.date}`,
          'booking',
          { bookingId, bookingNumber: booking.bookingNumber }
        )
      );
    }

    if (booking.staffId) {
      notifications.push(
        sendPushNotification(
          booking.staffId,
          '📋 New Assignment',
          `You have been assigned to ${booking.customerName}'s booking at ${booking.bookingTime || booking.time} on ${booking.bookingDate || booking.date}`,
          'booking',
          { bookingId, bookingNumber: booking.bookingNumber }
        )
      );
    }

    await Promise.allSettled(notifications);
    logger.log(`✅ Booking ${bookingId} processed`);

  } catch (error) {
    logger.error('Error in onBookingCreated:', error);
  }
});

exports.onBookingUpdated = onDocumentUpdated('bookings/{bookingId}', async (event) => {
  const beforeData = event.data?.before?.data();
  const afterData = event.data?.after?.data();
  const bookingId = event.params.bookingId;

  if (!beforeData || !afterData || beforeData.status === afterData.status) {
    logger.log('⏭️ No status change');
    return;
  }

  logger.log(`🔄 Booking ${bookingId} status: ${beforeData.status} → ${afterData.status}`);

  try {
    let title = '', body = '';

    if (afterData.customerId) {
      // Portal canonical statuses: upcoming | in-progress | cancelled | closed
      switch (String(afterData.status || '').toLowerCase()) {
        case 'upcoming':
        case 'approved':
        case 'confirmed':
        case 'pending':
          title = '📅 Booking Updated';
          body = `Your booking #${afterData.bookingNumber} for ${afterData.serviceName} is scheduled for ${afterData.bookingDate || afterData.date} at ${afterData.bookingTime || afterData.time}.`;
          break;
        case 'in-progress':
        case 'in_progress':
          title = '🔄 Service Started';
          body = `Your ${afterData.serviceName} at ${afterData.branch} is now in progress.`;
          break;
        case 'closed':
        case 'completed':
          title = '✨ Service Completed';
          body = `Thank you for visiting ${afterData.branch}! We hope you enjoyed your ${afterData.serviceName}.`;
          break;
        case 'cancelled':
        case 'canceled':
          title = '❌ Booking Cancelled';
          body = `Your booking #${afterData.bookingNumber} for ${afterData.serviceName} has been cancelled.`;
          if (afterData.notes) body += ` Reason: ${afterData.notes}`;
          break;
      }

      if (title) {
        await sendPushNotification(
          afterData.customerId,
          title,
          body,
          'booking',
          { bookingId, bookingNumber: afterData.bookingNumber, status: afterData.status }
        );
      }
    }

    if (afterData.staffId && afterData.staffId !== beforeData.staffId) {
      await sendPushNotification(
        afterData.staffId,
        '📋 New Assignment',
        `You have been assigned to ${afterData.customerName}'s booking for ${afterData.serviceName} at ${afterData.bookingTime || afterData.time} on ${afterData.bookingDate || afterData.date}`,
        'booking',
        { bookingId, bookingNumber: afterData.bookingNumber }
      );
    }

    if (afterData.status === 'cancelled' && afterData.branch) {
      await sendToBranch(
        afterData.branch,
        '⚠️ Booking Cancelled',
        `Booking #${afterData.bookingNumber} - ${afterData.customerName} cancelled ${afterData.serviceName}`,
        'booking',
        { bookingId, bookingNumber: afterData.bookingNumber }
      );
    }
  } catch (error) {
    logger.error('Error in onBookingUpdated:', error);
  }
});

// ============================================================
// 🔥 LOYALTY POINTS NOTIFICATIONS
// ============================================================

exports.onLoyaltyPointsAwarded = onDocumentCreated('loyaltyTransactions/{transactionId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const transaction = snapshot.data();
  const transactionId = event.params.transactionId;

  if (transaction.customerId && transaction.points) {
    const source = transaction.source || transaction.description || 'loyalty program';
    const points = transaction.points || 0;

    await sendPushNotification(
      transaction.customerId,
      '🎉 Loyalty Points Earned!',
      `You earned ${points} points from ${source}`,
      'loyalty',
      {
        transactionId,
        points: points,
        source: source
      }
    );
  }
});

// ============================================================
// 🔥 ORDER NOTIFICATIONS
// ============================================================

exports.onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const order = snapshot.data();
  const orderId = event.params.orderId;

  logger.log(`🛍️ New order created: ${orderId}`);

  try {
    if (order.customerId) {
      await sendPushNotification(
        order.customerId,
        '🛍️ Order Placed Successfully!',
        `Your order #${order.transactionId} has been placed. Total: ${formatCurrency(order.totalAmount)}`,
        'order',
        { orderId, transactionId: order.transactionId, totalAmount: order.totalAmount }
      );
    }

    const branchName = order.pickupBranch || (order.branchNames && order.branchNames[0]);
    if (branchName) {
      await sendToBranch(
        branchName,
        '🛒 New Order Received',
        `Order #${order.transactionId} from ${order.customerName} - ${formatCurrency(order.totalAmount)}`,
        'order',
        { orderId, transactionId: order.transactionId }
      );
    }
  } catch (error) {
    logger.error('Error in onOrderCreated:', error);
  }
});

exports.onOrderUpdated = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  const orderId = event.params.orderId;

  if (!before || !after || before.status === after.status) return;

  logger.log(`📦 Order ${orderId} status: ${before.status} → ${after.status}`);

  try {
    let title = '', body = '';

    switch (after.status) {
      case 'approved':
        title = '✅ Order Approved';
        body = `Your order #${after.transactionId} has been approved and is being processed.`;
        break;
      case 'shipped':
        title = '🚚 Order Shipped';
        body = `Your order #${after.transactionId} is on the way! Expected delivery: ${after.expectedDeliveryDate || 'soon'}`;
        break;
      case 'completed':
        title = '📬 Order Ready for Pickup';
        body = `Your order #${after.transactionId} is ready for pickup at ${after.pickupBranch || 'your selected branch'}`;
        break;
      case 'cancelled':
        title = '❌ Order Cancelled';
        body = `Your order #${after.transactionId} has been cancelled.`;
        break;
    }

    if (title && after.customerId) {
      await sendPushNotification(
        after.customerId,
        title,
        body,
        'order',
        { orderId, transactionId: after.transactionId, status: after.status }
      );
    }
  } catch (error) {
    logger.error('Error in onOrderUpdated:', error);
  }
});

// ============================================================
// 🔥 OFFER NOTIFICATIONS
// ============================================================

exports.onOfferCreated = onDocumentCreated('offers/{offerId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const offer = snapshot.data();
  const offerId = event.params.offerId;

  logger.log(`🎉 New offer created: ${offer.title}`);

  try {
    const title = '🎉 New Offer Available!';
    const discountText = offer.discountValue ? `${offer.discountValue}${offer.discountType === 'percentage' ? '%' : ' AED'} off` : '';
    const body = `${offer.title} - ${discountText || 'Special offer just for you!'}`;

    await messaging.sendToTopic('offers', {
      notification: { title, body },
      data: {
        type: 'offer',
        offerId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: NOTIFICATION_CONFIG.android,
      apns: NOTIFICATION_CONFIG.apns
    });

    logger.log('✅ Offer notification sent to topic: offers');
  } catch (error) {
    logger.error('Error in onOfferCreated:', error);
  }
});

// ============================================================
// 🔥 CHAT NOTIFICATIONS
// ============================================================

exports.onNewChatMessage = onDocumentCreated('chatRooms/{roomId}/messages/{messageId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const message = snapshot.data();
  const { roomId, messageId } = event.params;

  if (!message || !message.senderId) return;

  try {
    const roomDoc = await db.collection('chatRooms').doc(roomId).get();
    if (!roomDoc.exists) return;

    const room = roomDoc.data();
    const recipientId = room.participants?.find(id => id !== message.senderId);

    if (!recipientId || recipientId === message.senderId) return;

    const senderName = message.senderName ||
                      (room.participantNames && room.participantNames[message.senderId]) ||
                      'Someone';

    await sendPushNotification(
      recipientId,
      `💬 Message from ${senderName}`,
      message.content || message.text || 'Sent a message',
      'chat',
      {
        roomId,
        messageId,
        senderId: message.senderId,
        senderName
      }
    );

    logger.log(`✅ Chat notification sent to ${recipientId}`);
  } catch (error) {
    logger.error('Error in onNewChatMessage:', error);
  }
});

exports.totalpayWebhook = onRequest(async (req, res) => {
    if (req.method !== 'POST') {
        res.status(405).send('Method Not Allowed');
        return;
    }

    try {
        const payload = req.body;
        const { transactionId, status, orderId } = payload;

        console.log(`Webhook received: Trans ID ${transactionId}, Status ${status}`);

        const paymentsRef = db.collection('payments');
        const snapshot = await paymentsRef.where('gatewayTransactionId', '==', transactionId).limit(1).get();

        if (!snapshot.empty) {
            const paymentDoc = snapshot.docs[0];
            const paymentData = paymentDoc.data();
            const { referenceType, referenceId } = paymentData;

            await paymentDoc.ref.update({
                status: status === 'SUCCESS' ? 'succeeded' : 'failed',
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            if (referenceType === 'booking') {
                await db.collection('bookings').doc(referenceId).update({
                    paymentStatus: status === 'SUCCESS' ? 'paid' : 'failed',
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        res.status(200).send('Webhook received successfully');
    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).send('Internal Server Error');
    }
});

// ============================================================
// 🔥 SCHEDULED FUNCTIONS
// ============================================================

exports.sendBookingReminders = onSchedule('* * * * *', async (event) => {
  const now = new Date();
  const todayDate = formatDate(now);

  const bookings = await db
    .collection('bookings')
    .where('status', '==', 'approved')
    .where('date', '==', todayDate)
    .get();

  for (const doc of bookings.docs) {
    const booking = doc.data();
    const bookingTime = parseTime(booking.bookingTime || booking.time);
    const bookingDateTime = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      bookingTime.hours,
      bookingTime.minutes
    );

    const timeDiff = (bookingDateTime - now) / (1000 * 60);

    if (timeDiff > 55 && timeDiff < 65) {
      await sendPushNotification(
        booking.customerId,
        '⏰ Booking Reminder',
        `Your ${booking.serviceName} appointment is in 1 hour at ${booking.bookingTime || booking.time}`,
        'booking',
        { bookingId: doc.id, bookingNumber: booking.bookingNumber }
      );
    }
  }
});

// ============================================================
// 🔥 CORE FCM SENDING FUNCTIONS
// ============================================================

async function sendPushNotification(userId, title, body, type, data = {}) {
  try {
    const tokensSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('fcmTokens')
      .where('active', '==', true)
      .get();

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

    if (tokens.length === 0) {
      logger.log(`No active FCM tokens for user: ${userId}`);
      return;
    }

    logger.log(`📱 Sending to ${tokens.length} devices for user: ${userId}`);

    const payload = {
      notification: { title, body },
      data: {
        type,
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        timestamp: Date.now().toString()
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          sound: 'alert_sound',
          icon: '@mipmap/ic_launcher',
          color: '#C5A059',
          defaultSound: false
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'alert_sound.mp3',
            badge: 1,
            'content-available': 1
          }
        },
        headers: {
          'apns-priority': '10'
        }
      },
      tokens
    };

    const response = await messaging.sendEachForMulticast(payload);

    logger.log(`✅ Success: ${response.successCount}, Failed: ${response.failureCount}`);

    if (response.failureCount > 0) {
      await cleanupInvalidTokens(userId, tokens, response.responses);
    }
  } catch (error) {
    logger.error('Error sending push notification:', error);
  }
}

async function sendToBranch(branchName, title, body, type, data = {}) {
  try {
    const usersSnapshot = await db
      .collection('users')
      .where('branchName', '==', branchName)
      .get();

    for (const userDoc of usersSnapshot.docs) {
      await sendPushNotification(userDoc.id, title, body, type, data);
    }

    logger.log(`✅ Sent to ${usersSnapshot.size} users in branch: ${branchName}`);
  } catch (error) {
    logger.error('Error sending to branch:', error);
  }
}

async function cleanupInvalidTokens(userId, tokens, responses) {
  try {
    const permanentlyInvalidTokens = [];

    responses.forEach((resp, idx) => {
      if (!resp.success) {
        const errorCode = resp.error?.code;

        if (errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered') {
          permanentlyInvalidTokens.push(tokens[idx]);
        }
      }
    });

    for (const token of permanentlyInvalidTokens) {
      const tokenDocs = await db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .where('token', '==', token)
        .get();

      tokenDocs.docs.forEach(doc => {
        doc.ref.update({ active: false });
      });
    }
  } catch (error) {
    logger.error('Error cleaning up invalid tokens:', error);
  }
}

// ============================================================
// 🔥 UTILITY FUNCTIONS
// ============================================================
function formatCurrency(amount) {
  return new Intl.NumberFormat('en-AE', {
    style: 'currency',
    currency: 'AED',
    minimumFractionDigits: 2
  }).format(amount);
}

function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function parseTime(timeStr) {
  if (!timeStr) return { hours: 0, minutes: 0 };

  if (timeStr.includes(' ')) {
    const [time, period] = timeStr.split(' ');
    let [hours, minutes] = time.split(':').map(Number);

    if (period === 'PM' && hours !== 12) hours += 12;
    if (period === 'AM' && hours === 12) hours = 0;

    return { hours, minutes: minutes || 0 };
  } else {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return { hours, minutes: minutes || 0 };
  }
}
