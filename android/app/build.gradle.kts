import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// S17-05: las llaves de firma viven FUERA de Git, en android/key.properties
// (ignorado en android/.gitignore). Ver android/key.properties.example.
// En CI ese archivo se arma con GitHub Secrets (ver release.yml).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "gt.edu.umes.inkashd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // S17-04: el applicationId es la identidad PERMANENTE en Google Play.
        // Play rechaza com.example.*, y una vez publicado no se puede cambiar.
        // Sin guion bajo ni "_d": los ids de iOS/macOS no aceptan "_", así
        // que usamos el mismo id en las tres plataformas.
        applicationId = "gt.edu.umes.inkashd"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Con key.properties: firma de release (la que acepta Play).
            // Sin él (compu de un estudiante, CI de PRs): firma de debug, para
            // que `flutter run --release` siga funcionando. Play RECHAZA un
            // AAB firmado con la llave de debug.
            signingConfig =
                if (hasReleaseKey) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
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
