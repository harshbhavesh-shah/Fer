plugins {
    // Bumped to the latest stable 8.x line (avoiding the AGP 9.x major jump)
    // to satisfy Haze 1.7.2's own dependency metadata, which requires AGP >= 8.9.1.
    id("com.android.application") version "8.13.2" apply false
    // Haze 1.7.2's POM requires kotlin-stdlib 2.2.21 — our compiler must be
    // able to read metadata at least that new (same lesson as the 1.5.1 bump:
    // a too-old compiler can't even read basic stdlib calls like runCatching).
    // The Compose Compiler lives in the Kotlin plugin itself since Kotlin 2.0,
    // hence the compose plugin line below replacing the old
    // composeOptions.kotlinCompilerExtensionVersion mechanism.
    id("org.jetbrains.kotlin.android") version "2.2.21" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
