import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningFile = rootProject.file("key.properties")
val releaseSigning = Properties().apply {
    if (releaseSigningFile.exists()) releaseSigningFile.inputStream().use { load(it) }
}

android {
    namespace = "com.example.split_debt"
    compileSdk = maxOf(35, flutter.compileSdkVersion)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.split_debt"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Match MaterialApp.supportedLocales; discard unused plugin translations.
        resourceConfigurations += listOf("vi", "en")
    }

    signingConfigs {
        if (releaseSigningFile.exists()) {
            create("release") {
                storeFile = rootProject.file(requireNotNull(releaseSigning.getProperty("storeFile")))
                storePassword = requireNotNull(releaseSigning.getProperty("storePassword"))
                keyAlias = requireNotNull(releaseSigning.getProperty("keyAlias"))
                keyPassword = requireNotNull(releaseSigning.getProperty("keyPassword"))
            }
        }
    }
    buildTypes {
        release {
            // Keep unused Android code and resources out of every release APK.
            isMinifyEnabled = true
            isShrinkResources = true

            // Never distribute an APK signed with a shared debug key.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Debug builds still work without a release keystore.
gradle.taskGraph.whenReady {
    if (allTasks.any { it.name == "assembleRelease" || it.name == "bundleRelease" } &&
        !releaseSigningFile.exists()) {
        throw GradleException("Missing android/key.properties. Configure release signing before building an APK.")
    }
}
