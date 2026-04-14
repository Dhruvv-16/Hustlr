import { initializeApp, getApp, getApps } from 'firebase/app'
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
} from 'firebase/auth'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

const requiredConfigKeys = ['apiKey', 'authDomain', 'projectId', 'appId']

const ensureFirebaseConfig = () => {
  const missingKeys = requiredConfigKeys.filter((key) => !firebaseConfig[key])
  if (missingKeys.length) {
    throw new Error(`Firebase is not configured: missing ${missingKeys.join(', ')}`)
  }
}

const getFirebaseApp = () => {
  ensureFirebaseConfig()
  if (!getApps().length) {
    return initializeApp(firebaseConfig)
  }
  return getApp()
}

const app = getFirebaseApp()
export const auth = getAuth(app)

export const signInWithGoogle = async () => {
  const provider = new GoogleAuthProvider()
  provider.setCustomParameters({ prompt: 'select_account' })
  try {
    const result = await signInWithPopup(auth, provider)
    const idToken = await result.user.getIdToken()
    return {
      uid: result.user.uid,
      name: result.user.displayName,
      email: result.user.email,
      photo: result.user.photoURL,
      phone: result.user.phoneNumber,
      idToken,
    }
  } catch (err) {
    if (err.code === 'auth/popup-blocked' || err.code === 'auth/cancelled-popup-request') {
      throw new Error('Popup was blocked. Please allow popups for this site.')
    }
    throw err
  }
}

export const signUpWithEmail = async (email, password, name) => {
  try {
    const result = await createUserWithEmailAndPassword(auth, email, password)
    const idToken = await result.user.getIdToken()
    return {
      uid: result.user.uid,
      name: name,
      email: result.user.email,
      idToken,
    }
  } catch (err) {
    throw err
  }
}

export const signInWithEmail = async (email, password) => {
  try {
    const result = await signInWithEmailAndPassword(auth, email, password)
    const idToken = await result.user.getIdToken()
    return {
      uid: result.user.uid,
      name: result.user.displayName,
      email: result.user.email,
      idToken,
    }
  } catch (err) {
    throw err
  }
}
