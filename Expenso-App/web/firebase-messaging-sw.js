importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCaVJyfxxTxn5OjIr8dWI9m-kSAP9fM81E",
  authDomain: "wallet-13f58.firebaseapp.com",
  projectId: "wallet-13f58",
  storageBucket: "wallet-13f58.firebasestorage.app",
  messagingSenderId: "1062989154840",
  appId: "1:1062989154840:web:759ee1546e8746020dd16d"
});

const messaging = firebase.messaging();
