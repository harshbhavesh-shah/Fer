package com.harshbshah.fer

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.firestore.ktx.persistentCacheSettings
import com.google.firebase.ktx.Firebase

class FerApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        // Persistent local cache, same as iOS's PersistentCacheSettings — gives us
        // offline reads/writes that sync automatically once connectivity returns.
        Firebase.firestore.firestoreSettings = FirebaseFirestoreSettings.Builder()
            .setLocalCacheSettings(persistentCacheSettings {})
            .build()
        container = AppContainer(this)
    }
}
