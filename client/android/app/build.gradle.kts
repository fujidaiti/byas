import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The native SaveWebArticleActivity cannot read Flutter's `--dart-define-from-file=.env`
// value (that is Dart-only), so we read the same client/.env here and bake API_BASE_URL
// into BuildConfig. `.env` is a plain KEY=value file, parsed via java.util.Properties.
// Falls back to the emulator host loopback (Prism mock) when .env is absent (e.g. CI).
val apiBaseUrl: String =
    run {
        val envFile = rootProject.file("../.env") // client/android -> client/.env
        val fallback = "http://10.0.2.2:4010"
        if (!envFile.exists()) {
            fallback
        } else {
            val props = Properties()
            envFile.inputStream().use { props.load(it) }
            props.getProperty("API_BASE_URL")?.trim()?.takeIf { it.isNotEmpty() } ?: fallback
        }
    }

dependencies {
    // Patrol: https://patrol.leancode.co/documentation
    androidTestUtil("androidx.test:orchestrator:1.5.1")

    // Jetpack Compose (share sheet activity UI). BOM pins all androidx.compose.* versions.
    val composeBom = platform("androidx.compose:compose-bom:2026.06.00")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.activity:activity-compose:1.10.0")
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
        // Required on AGP 8+/9 for BuildConfig.API_BASE_URL to be generated.
        buildConfig = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "dev.norelease.paperdoll"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Patrol: https://patrol.leancode.co/documentation
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"

        // Base URL for the native reading-list POST (see apiBaseUrl above).
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
