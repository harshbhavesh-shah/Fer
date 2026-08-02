package com.harshbshah.fer.data.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.UserProfileChangeRequest
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.tasks.await

/** Wraps Firebase Auth — same shape as iOS's AuthService. */
class AuthRepository(private val firestoreRepository: FirestoreRepository) {
    private val auth = FirebaseAuth.getInstance()

    private val _currentUser = MutableStateFlow(auth.currentUser)
    val currentUser: StateFlow<FirebaseUser?> = _currentUser

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    init {
        auth.addAuthStateListener { a ->
            _currentUser.value = a.currentUser
            _isLoading.value = false
        }
    }

    val isSignedIn: Boolean get() = auth.currentUser != null
    val uid: String? get() = auth.currentUser?.uid

    fun clearError() { _errorMessage.value = null }

    suspend fun signIn(email: String, password: String) {
        _errorMessage.value = null
        try {
            auth.signInWithEmailAndPassword(email, password).await()
        } catch (e: Exception) {
            _errorMessage.value = e.localizedMessage ?: "Sign in failed."
        }
    }

    suspend fun signUp(email: String, password: String, displayName: String) {
        _errorMessage.value = null
        try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            val user = result.user
            user?.updateProfile(
                UserProfileChangeRequest.Builder().setDisplayName(displayName).build()
            )?.await()
            user?.let {
                firestoreRepository.createUserProfile(it.uid, displayName, email)
            }
        } catch (e: Exception) {
            _errorMessage.value = e.localizedMessage ?: "Sign up failed."
        }
    }

    fun signOut() {
        auth.signOut()
    }

    suspend fun resetPassword(email: String) {
        _errorMessage.value = null
        try {
            auth.sendPasswordResetEmail(email).await()
        } catch (e: Exception) {
            _errorMessage.value = e.localizedMessage ?: "Couldn't send reset email."
        }
    }
}
