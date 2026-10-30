plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.terry.dompetgueh.offline"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "id.terry.dompetgueh.offline"
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("localRelease") {
            storeFile = rootProject.file("signing/dompetgueh.jks")
            storePassword = "dompetgueh-offline"
            keyAlias = "dompetgueh"
            keyPassword = "dompetgueh-offline"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("localRelease")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303")
}
