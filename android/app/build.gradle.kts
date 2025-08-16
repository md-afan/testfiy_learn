plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
   namespace = "com.example.testify_learn_application"
    
  
    compileSdk = 35
    ndkVersion = "27.0.12077973"

   compileOptions {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
    isCoreLibraryDesugaringEnabled = true
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_1_8.toString()
}

    defaultConfig {
        applicationId = "com.example.testify_learn_application"
        minSdk = 23
        targetSdk = 33
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))

    // ✅ Correct Kotlin string for desugaring dependency
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase dependencies here as needed
}
