import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val apiBaseUrl: String =
    run {
        val envFile = rootProject.file("../.env")
        if (!envFile.exists()) {
            throw GradleException(".env not found.")
        }
        val props = Properties()
        envFile.inputStream().use { props.load(it) }
        props.getProperty("API_BASE_URL")?.trim()?.takeIf { it.isNotEmpty() }
            ?: throw GradleException("API_BASE_URL is missing or empty.")
    }

dependencies {
    // Patrol: https://patrol.leancode.co/documentation
    androidTestUtil("androidx.test:orchestrator:1.5.1")

    // Jetpack Compose (share sheet activity UI). BOM pins all androidx.compose.* versions.
    val composeBom = platform("androidx.compose:compose-bom:2026.06.00")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.activity:activity-compose")

    // Key-value storage backing TokenStore, readable both from the Flutter engine
    // (via MethodChannel) and from SaveWebClipActivity outside of it; see TokenStore.
    implementation("androidx.datastore:datastore-preferences:1.2.1")
}

android {
    namespace = "dev.norelease.paperdoll"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.norelease.paperdoll"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol: https://patrol.leancode.co/documentation
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"

        // Base URL for the native reading-list POST
        buildConfigField("String", "API_BASE_URL", "\"$apiBaseUrl\"")
    }

    // Patrol: https://patrol.leancode.co/documentation
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
