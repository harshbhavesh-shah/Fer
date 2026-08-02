package com.harshbshah.fer.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.data.repository.FirestoreRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class RoutinesViewModel(private val repository: FirestoreRepository) : ViewModel() {
    private val _routines = MutableStateFlow<List<RoutineTemplate>>(emptyList())
    val routines: StateFlow<List<RoutineTemplate>> = _routines

    init {
        viewModelScope.launch {
            repository.routinesFlow().collect { _routines.value = it }
        }
    }

    fun save(routine: RoutineTemplate) {
        viewModelScope.launch { runCatching { repository.saveRoutine(routine) } }
    }

    fun delete(routine: RoutineTemplate) {
        val id = routine.id ?: return
        viewModelScope.launch { runCatching { repository.deleteRoutine(id) } }
    }

    fun markUsed(routine: RoutineTemplate) {
        val id = routine.id ?: return
        repository.markRoutineUsed(id)
    }
}
