importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyDNZ-MurkykqthuDoKvANflhP6GmrL_Bek',
    appId: '1:178689790799:web:885f654c59f0262e652b3a',
    messagingSenderId: '178689790799',
    projectId: 'period-tracker-02b22',
    authDomain: 'period-tracker-02b22.firebaseapp.com',
    storageBucket: 'period-tracker-02b22.firebasestorage.app',
    measurementId: 'G-KPB46JJFB8',
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
