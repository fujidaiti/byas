import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val apiBaseUrl: String = run {
    val envFile = rootProject.file("../.env")
    if (!envFile.exists()) {
        throw GradleException(".env not found.")
    }
    val props = Properties()
    envFile.inputStream().use { props.load(it) }
    props.getProperty("API_BASE_URL")?.trim()?.takeIf { it.isNotEmpty() }
        ?: throw GradleException("API_BASE_URL is missing or empty.")
}

val signingPropertiesFile = rootProject.file("signing.properties")

// Release builds require the credentials, so fail up front instead of building
// for minutes first. Debug and profile builds never reach this task.
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    doFirst {
        if (!signingPropertiesFile.exists()) {
            throw GradleException("$signingPropertiesFile not found, which is required in release builds.")
        }
    }
}

val signingProperties = Properties().apply {
    if (signingPropertiesFile.exists()) {
        signingPropertiesFile.inputStream().use { load(it) }
    }
}

fun resolveSigningProperty(key: String): String {
    return signingProperties.getProperty(key)
        ?: throw GradleException("Signing property '$key' is missing.")
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

    // Key-value storage backing SecureStorage.
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

    signingConfigs {
        create("release") {
            // Left unconfigured when signing.properties is missing so that debug builds still configure.
            if (signingPropertiesFile.exists()) {
                storeFile = file(resolveSigningProperty("keystore.path"))
                storePassword = resolveSigningProperty("keystore.storePassword")
                keyAlias = resolveSigningProperty("keystore.keyAlias")
                keyPassword = resolveSigningProperty("keystore.keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
