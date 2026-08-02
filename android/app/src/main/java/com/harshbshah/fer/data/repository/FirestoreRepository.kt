package com.harshbshah.fer.data.repository

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.harshbshah.fer.data.ExerciseLibrary
import com.harshbshah.fer.data.model.RoutineTemplate
import com.harshbshah.fer.data.model.SetEntry
import com.harshbshah.fer.data.model.UserProfile
import com.harshbshah.fer.data.model.WorkoutSession
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import java.util.Date

/**
 * All Firestore reads/writes live here — mirrors `Fer/Services/FirestoreService.swift`.
 * Firestore's Android SDK persists data locally and syncs automatically, so this
 * gives offline support for free, same as the iOS persistent cache.
 *
 * Firestore layout (shared with iOS — do not change without updating both apps):
 *   users/{uid}                                 -> UserProfile
 *   users/{uid}/routines/{routineId}             -> RoutineTemplate
 *   users/{uid}/workouts/{workoutId}             -> WorkoutSession
 *   users/{uid}/customExercises/{exerciseId}     -> Exercise
 */
class FirestoreRepository {
    private val db = FirebaseFirestore.getInstance()

    class NotSignedInException : Exception("You need to be signed in to sync data.")

    private val currentUid: String? get() = FirebaseAuth.getInstance().currentUser?.uid

    private fun requireUid(): String = currentUid ?: throw NotSignedInException()

    // MARK: - User profile

    suspend fun createUserProfile(uid: String, displayName: String, email: String) {
        val profile = UserProfile(displayName = displayName, email = email)
        db.collection("users").document(uid).set(profile).await()
    }

    suspend fun fetchUserProfile(): UserProfile? {
        val uid = requireUid()
        val snapshot = db.collection("users").document(uid).get().await()
        return snapshot.toObject(UserProfile::class.java)?.also { it.id = snapshot.id }
    }

    // MARK: - Routines

    fun routinesFlow(): Flow<List<RoutineTemplate>> = callbackFlow {
        val uid = currentUid
        if (uid == null) {
            trySend(emptyList())
            awaitClose { }
            return@callbackFlow
        }
        val registration = db.collection("users").document(uid).collection("routines")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, _ ->
                val routines = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(RoutineTemplate::class.java)?.also { it.id = doc.id }
                } ?: emptyList()
                trySend(routines)
            }
        awaitClose { registration.remove() }
    }

    suspend fun saveRoutine(routine: RoutineTemplate) {
        val uid = requireUid()
        val toSave = routine.copy(ownerId = uid)
        val ref = if (routine.id != null) {
            db.collection("users").document(uid).collection("routines").document(routine.id!!)
        } else {
            db.collection("users").document(uid).collection("routines").document()
        }
        ref.set(toSave).await()
    }

    suspend fun deleteRoutine(id: String) {
        val uid = requireUid()
        db.collection("users").document(uid).collection("routines").document(id).delete().await()
    }

    fun markRoutineUsed(id: String) {
        val uid = currentUid ?: return
        db.collection("users").document(uid).collection("routines").document(id)
            .update("lastUsedAt", Date())
    }

    // MARK: - Workouts

    fun workoutsFlow(): Flow<List<WorkoutSession>> = callbackFlow {
        val uid = currentUid
        if (uid == null) {
            trySend(emptyList())
            awaitClose { }
            return@callbackFlow
        }
        val registration = db.collection("users").document(uid).collection("workouts")
            .orderBy("startedAt", Query.Direction.DESCENDING)
            .limit(200)
            .addSnapshotListener { snapshot, _ ->
                val workouts = snapshot?.documents?.mapNotNull { doc ->
                    doc.toObject(WorkoutSession::class.java)?.also { it.id = doc.id }
                } ?: emptyList()
                trySend(workouts)
            }
        awaitClose { registration.remove() }
    }

    suspend fun saveWorkout(workout: WorkoutSession): String {
        val uid = requireUid()
        val toSave = workout.copy(ownerId = uid)
        val ref = if (workout.id != null) {
            db.collection("users").document(uid).collection("workouts").document(workout.id!!)
        } else {
            db.collection("users").document(uid).collection("workouts").document()
        }
        ref.set(toSave).await()
        return ref.id
    }

    suspend fun deleteWorkout(id: String) {
        val uid = requireUid()
        db.collection("users").document(uid).collection("workouts").document(id).delete().await()
    }

    /** Historical sets for a specific exercise, oldest first, for progress charts. */
    fun history(exerciseId: String, workouts: List<WorkoutSession>): List<Pair<Date, SetEntry>> {
        return workouts.mapNotNull { workout ->
            val logged = workout.exercises.firstOrNull { it.exerciseId == exerciseId } ?: return@mapNotNull null
            val completed = logged.sets.filter { it.isCompleted && !it.isWarmup }
            val best = completed.maxByOrNull { it.weight * it.reps } ?: return@mapNotNull null
            workout.startedAt to best
        }.sortedBy { it.first }
    }
}
