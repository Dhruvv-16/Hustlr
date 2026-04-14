package com.example.winkit.data

import android.app.Activity
import android.util.Log
import com.google.firebase.FirebaseException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.PhoneAuthCredential
import com.google.firebase.auth.PhoneAuthOptions
import com.google.firebase.auth.PhoneAuthProvider
import java.util.concurrent.TimeUnit

class FirebaseAuthHelper(private val activity: Activity) {
    private val auth = FirebaseAuth.getInstance()
    private var storedVerificationId: String = ""

    // 1. Send the SMS
    fun sendOtp(
        phoneNumber: String,
        onCodeSent: () -> Unit,
        onError: (String) -> Unit
    ) {
        val callbacks = object : PhoneAuthProvider.OnVerificationStateChangedCallbacks() {
            override fun onVerificationCompleted(credential: PhoneAuthCredential) {
                // Auto-retrieval (sometimes happens on Android, we can just sign in)
                signInWithPhoneAuthCredential(credential, { }, onError)
            }

            override fun onVerificationFailed(e: FirebaseException) {
                Log.e("FirebaseAuth", "Verification failed", e)
                onError(e.message ?: "Verification failed")
            }

            override fun onCodeSent(
                verificationId: String,
                token: PhoneAuthProvider.ForceResendingToken
            ) {
                // Save the ID so we can use it to verify the code they type later
                storedVerificationId = verificationId
                onCodeSent() 
            }
        }

        val options = PhoneAuthOptions.newBuilder(auth)
            .setPhoneNumber("+91$phoneNumber") // Hardcoded to Indian code for the pitch
            .setTimeout(60L, TimeUnit.SECONDS)
            .setActivity(activity)
            .setCallbacks(callbacks)
            .build()
        PhoneAuthProvider.verifyPhoneNumber(options)
    }

    // 2. Verify what the user typed
    fun verifyOtp(
        code: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        if (storedVerificationId.isEmpty()) {
            onError("Something went wrong. Please request OTP again.")
            return
        }
        val credential = PhoneAuthProvider.getCredential(storedVerificationId, code)
        signInWithPhoneAuthCredential(credential, onSuccess, onError)
    }

    private fun signInWithPhoneAuthCredential(
        credential: PhoneAuthCredential,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        auth.signInWithCredential(credential)
            .addOnCompleteListener(activity) { task ->
                if (task.isSuccessful) {
                    onSuccess()
                } else {
                    Log.e("FirebaseAuth", "Sign in failed", task.exception)
                    onError(task.exception?.message ?: "Invalid OTP")
                }
            }
    }
}
