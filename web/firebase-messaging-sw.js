importScripts('https://www.gstatic.com/firebasejs/9.1.3/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.3/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyAExUowQ4GSSCdMwzMnuhN-Axv6ezFtEfg",
    authDomain: "testify-learn-d58e0.firebaseapp.com",
    projectId: "testify-learn-d58e0",
    storageBucket: "testify-learn-d58e0.firebasestorage.app",
    messagingSenderId: "868279158213",
    appId: "1:868279158213:web:c133cc449778bea368f7ac",
});

const messaging = firebase.messaging();

// messaging.onBackgroundMessage(function (payload) {
//     console.log('[firebase-messaging-sw.js] Background message ', payload);
//     const notificationTitle = payload.notification.title || 'New Notification';
//     const notificationOptions = {
//         body: payload.notification.body,
//         icon: '/icons/icon-192.png', // optional
//     };

//     self.registration.showNotification(notificationTitle, notificationOptions);
// });