importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAe9TdHxKi2Aa0ANh3wZWkUOiHPR5u094k",
  appId: "1:403643543889:web:09434842b87df9163ae370",
  messagingSenderId: "403643543889",
  projectId: "kindmap-999d3",
  authDomain: "kindmap-999d3.firebaseapp.com",
  storageBucket: "kindmap-999d3.appspot.com",
});

const messaging = firebase.messaging();
