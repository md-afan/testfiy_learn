// firebase.js
import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

// 🔴 Replace this config with your Firebase project's actual config
const firebaseConfig = {
  apiKey: "AIzaSyAExUowQ4GSSCdMwzMnuhN-Axv6ezFtEfg",
          authDomain: "testify-learn-d58e0.firebaseapp.com",
          projectId: "testify-learn-d58e0",
          storageBucket: "testify-learn-d58e0.firebasestorage.app",
          messagingSenderId: "868279158213",
          appId: "1:868279158213:web:c133cc449778bea368f7ac",
          measurementId: "G-YJBZNG4Z3S"
};

const app = initializeApp(firebaseConfig);

// 🔥 Firebase services
export const auth = getAuth(app);
export const provider = new GoogleAuthProvider();
export const db = getFirestore(app);
export const storage = getStorage(app);
