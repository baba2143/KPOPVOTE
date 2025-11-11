import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Firebase configuration
const firebaseConfig = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY || "AIzaSyDAr8pYSBI1LShAGcihpBwaDqvEWJfcRK0",
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN || "kpopvote-9de2b.firebaseapp.com",
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID || "kpopvote-9de2b",
  storageBucket: process.env.REACT_APP_FIREBASE_STORAGE_BUCKET || "kpopvote-9de2b.firebasestorage.app",
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID || "507852405431",
  appId: process.env.REACT_APP_FIREBASE_APP_ID || "1:507852405431:web:c850e316b0ba3ecffc6b32"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);

export default app;
