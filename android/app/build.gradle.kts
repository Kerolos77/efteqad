import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.exists()) {
    FileInputStream(releasePropertiesFile).use { releaseProperties.load(it) }
}
val releaseStorePath = releaseProperties.getProperty("storeFile")
val releaseStoreFile = releaseStorePath?.takeIf { it.isNotBlank() }?.let { rootProject.file(it) }
val validateReleaseSigning = tasks.register("validateReleaseSigning") {
    doLast {
        check(releasePropertiesFile.exists() &&
            listOf("keyAlias", "keyPassword", "storePassword", "storeFile").all {
                !releaseProperties.getProperty(it).isNullOrBlank()
            } && releaseStoreFile?.isFile == true) {
            "Release signing requires android/key.properties with nonempty keyAlias, keyPassword, storePassword, storeFile and an existing keystore."
        }
    }
}
tasks.configureEach {
    if (name != "validateReleaseSigning" && name.contains("Release")) {
        dependsOn(validateReleaseSigning)
    }
}

android {
    namespace = "com.example.efteqad"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Preserve the registered Firebase application identity.
        applicationId = "com.example.efteqad"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseProperties.getProperty("keyAlias")
            keyPassword = releaseProperties.getProperty("keyPassword")
            storeFile = releaseStoreFile
            storePassword = releaseProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
