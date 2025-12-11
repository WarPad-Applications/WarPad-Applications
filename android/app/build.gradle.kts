plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Plugin Firebase
}

android {
    namespace = "com.example.flutter_application" // <-- Pastikan sesuai package-mu
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        // Kita pakai Java 8 agar kompatibel dengan Desugaring
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        
        // --- PERBAIKAN UTAMA: AKTIFKAN DESUGARING ---
        isCoreLibraryDesugaringEnabled = true
        // --------------------------------------------
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.flutter_application" // <-- Sesuaikan jika beda
        
        minSdk = flutter.minSdkVersion // Minimal SDK 23 untuk Modul 6 (Firebase)
        targetSdk = flutter.targetSdkVersion
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

// --- BAGIAN INI WAJIB DITAMBAHKAN UNTUK DESUGARING ---
dependencies {
    // Library khusus agar fitur notifikasi jalan di Android lama
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
