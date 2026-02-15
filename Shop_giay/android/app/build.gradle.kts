plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.shop_app_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ID ứng dụng của bạn
        applicationId = "com.example.shop_app_flutter"
        
        // --- PHẦN QUAN TRỌNG ĐÃ SỬA ---
        minSdk = 21 
        // -------------------------------
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInteger()
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