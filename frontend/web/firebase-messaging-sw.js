// Firebase Cloud Messaging service worker.
// Configuration is loaded from the ignored `.env` Flutter asset so no key is
// committed in this source file. Firebase web client identifiers are public at
// runtime by design; backend/database secrets must never be placed here.

importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js'
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js'
);

function parseEnv(source) {
  return Object.fromEntries(
    source
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith('#') && line.includes('='))
      .map((line) => {
        const separator = line.indexOf('=');
        return [line.slice(0, separator), line.slice(separator + 1)];
      })
  );
}

const firebaseReady = fetch('/assets/.env', { cache: 'no-store' })
  .then((response) => {
    if (!response.ok) throw new Error('Không tải được cấu hình Firebase web.');
    return response.text();
  })
  .then((source) => {
    const env = parseEnv(source);
    firebase.initializeApp({
      apiKey: env.FIREBASE_WEB_API_KEY,
      authDomain: env.FIREBASE_WEB_AUTH_DOMAIN,
      projectId: env.FIREBASE_WEB_PROJECT_ID,
      storageBucket: env.FIREBASE_WEB_STORAGE_BUCKET,
      messagingSenderId: env.FIREBASE_WEB_MESSAGING_SENDER_ID,
      appId: env.FIREBASE_WEB_APP_ID,
      measurementId: env.FIREBASE_WEB_MEASUREMENT_ID
    });

    const messaging = firebase.messaging();
    messaging.onBackgroundMessage((payload) => {
      if (payload.notification) return;
      return self.registration.showNotification(
        payload.data?.title || 'SplitDebt',
        {
          body: payload.data?.body || 'Bạn có thông báo mới',
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          data: payload.data || {}
        }
      );
    });
  })
  .catch((error) => console.error('[FCM SW]', error));

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    firebaseReady.then(() =>
      clients
        .matchAll({ type: 'window', includeUncontrolled: true })
        .then((clientList) => {
          const openClient = clientList.find((client) => 'focus' in client);
          return openClient?.focus() || clients.openWindow?.('/') || null;
        })
    )
  );
});