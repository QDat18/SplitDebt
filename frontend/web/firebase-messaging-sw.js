// ============================================================================
// firebase-messaging-sw.js
// Firebase Cloud Messaging background service worker
//
// Đặt tại:
// frontend/web/firebase-messaging-sw.js
// ============================================================================

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js'
);

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js'
);

// ============================================================================
// Firebase Web config
// Project: splitdebt-8c3fa
// ============================================================================
firebase.initializeApp({
  apiKey: 'AIzaSyCdiMdo7cvmdEjj_3k063RV-AAj0l6A-7s',
  authDomain: 'splitdebt-8c3fa.firebaseapp.com',
  projectId: 'splitdebt-8c3fa',
  storageBucket: 'splitdebt-8c3fa.firebasestorage.app',
  messagingSenderId: '534922111462',
  appId: '1:534922111462:web:52cf4fa91bf487425f4e27',
  measurementId: 'G-V7PJSRN5M0'
});

const messaging = firebase.messaging();

// ============================================================================
// Background notification
// ============================================================================
messaging.onBackgroundMessage(function (payload) {
  // Firebase already displays notification payloads in the background.
  if (payload.notification) return;
  console.log(
    '[FCM SW] Background message received:',
    payload
  );

  const notificationTitle =
    payload.notification?.title ||
    payload.data?.title ||
    'SplitDebt';

  const notificationOptions = {
    body:
      payload.notification?.body ||
      payload.data?.body ||
      'Bạn có thông báo mới',

    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',

    data: payload.data || {},

    requireInteraction: false
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

// ============================================================================
// Khi click notification
// ============================================================================
self.addEventListener(
  'notificationclick',
  function (event) {
    console.log(
      '[FCM SW] Notification clicked:',
      event.notification
    );

    event.notification.close();

    event.waitUntil(
      clients
        .matchAll({
          type: 'window',
          includeUncontrolled: true
        })
        .then(function (clientList) {
          // Nếu SplitDebt đang mở -> focus tab hiện tại.
          for (const client of clientList) {
            if ('focus' in client) {
              return client.focus();
            }
          }

          // Nếu chưa mở -> mở app.
          if (clients.openWindow) {
            return clients.openWindow('/');
          }

          return null;
        })
    );
  }
);