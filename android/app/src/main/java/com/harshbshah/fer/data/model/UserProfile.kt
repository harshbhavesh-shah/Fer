package com.harshbshah.fer.data.model

import com.google.firebase.firestore.Exclude
import java.util.Date

data class UserProfile @JvmOverloads constructor(
    @get:Exclude @set:Exclude
    var id: String? = null,

    var displayName: String = "",
    var email: String = "",
    var weightUnit: WeightUnit = WeightUnit.lb,
    var createdAt: Date = Date()
) {
    enum class WeightUnit {
        lb, kg;

        val label: String get() = name
    }
}
