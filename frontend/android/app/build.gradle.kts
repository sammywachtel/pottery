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

android {
    namespace = "com.pottery.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.pottery.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("local") {
            dimension = "environment"
            applicationId = "com.pottery.app.local"
            resValue("string", "app_name", "Pottery Studio Local")
        }
        create("dev") {
            dimension = "environment"
            applicationId = "com.pottery.app.dev"
            resValue("string", "app_name", "Pottery Studio Dev")
        }
        create("prod") {
            dimension = "environment"
            applicationId = "com.pottery.app"
            resValue("string", "app_name", "Pottery Studio")
        }
    }

    // Opening move: Load signing configuration from external properties file
    // This saves us from hardcoding credentials in version control
    val keystorePropertiesFile = file("${System.getProperty("user.home")}/pottery-keystore/key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        create("release") {
            // Main play: Use release keystore if available, otherwise fall back to debug
            if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Victory lap: Sign with release config if available, otherwise use debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // This looks odd, but it saves us from build failures during development
                // Debug signing allows `flutter run --release` to work without keystore
                signingConfigs.getByName("debug")
            }

            // Main play: Strip native debug symbols to reduce AAB/APK size
            // Flutter handles code optimization, so we skip Java/Kotlin minification
            // This solves the "debug symbols not stripped" warning without breaking dependencies
            ndk {
                debugSymbolLevel = "SYMBOL_TABLE"
            }
        }
    }
}

flutter {
    source = "../.."
}
