package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.auth.FirebaseUser
import com.harshbshah.fer.data.repository.AuthRepository
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class AuthViewModel(private val repository: AuthRepository) : ViewModel() {
    val currentUser: StateFlow<FirebaseUser?> = repository.currentUser
    val isLoading: StateFlow<Boolean> = repository.isLoading
    val errorMessage: StateFlow<String?> = repository.errorMessage

    val isSignedIn: Boolean get() = repository.isSignedIn

    fun clearError() = repository.clearError()

    fun signIn(email: String, password: String, onDone: () -> Unit) {
        viewModelScope.launch {
            repository.signIn(email, password)
            onDone()
        }
    }

    fun signUp(email: String, password: String, displayName: String, onDone: () -> Unit) {
        viewModelScope.launch {
            repository.signUp(email, password, displayName)
            onDone()
        }
    }

    fun signOut() = repository.signOut()
}
