// app/build.gradle.kts - UPDATED FOR REAL NAVIGATION

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mumbaifirebrigade.casemonitoring"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.mfb.field"
        minSdk = 24  // Changed to 21 (required for Ola Navigation SDK)
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add this for better compatibility
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "android"
            storeFile = file("../../upload-keystore.jks")
            storePassword = "android"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }

    packaging {
        resources {
            excludes += setOf(
                "LICENSE.md",
                "LICENSE",
                "NOTICE",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/DEPENDENCIES",
                "META-INF/ASL2.0",
                "META-INF/LGPL2.1"
            )
        }
        pickFirst("**/OlaMapsHelperKt.class")
        pickFirst("**/OlaMapsHelperKt\$formatName\$1.class")
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
        pickFirst("**/libjscexecutor.so")
    }
}

dependencies {
    // ==========================================
    // OLA MAPS NAVIGATION SDK DEPENDENCIES
    // ==========================================
    
    // Ola Maps SDKs - Make sure these are the correct versions
    implementation(files("libs/OlaMapSdk-1.6.0.aar"))
    implementation(files("libs/maps-navigation-sdk-1.0.116-modified.aar"))
    implementation(files("libs/Places-sdk-2.3.9.jar"))
    
    // REQUIRED FOR OLA MAPS NAVIGATION SDK (from documentation)
    implementation("org.maplibre.gl:android-sdk:10.2.0")
    implementation("org.maplibre.gl:android-sdk-directions-models:5.9.0")
    implementation("org.maplibre.gl:android-sdk-services:5.9.0")
    implementation("org.maplibre.gl:android-sdk-turf:5.9.0")
    implementation("org.maplibre.gl:android-plugin-markerview-v9:1.0.0")
    implementation("org.maplibre.gl:android-plugin-annotation-v9:1.0.0")
    implementation("com.moengage:moe-android-sdk:12.6.01")
    
    // ==========================================
    // HTTP CLIENT FOR API CALLS
    // ==========================================
    
    // For HTTP requests to Ola APIs (routing, places, etc.)
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // For JSON parsing (if needed)
    implementation("com.squareup.retrofit2:converter-gson:2.11.0")
    implementation("com.squareup.retrofit2:retrofit:2.11.0")
    implementation("com.google.code.gson:gson:2.10.1")
    
    // ==========================================
    // KOTLIN COROUTINES (for async operations)
    // ==========================================
    
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    
    // ==========================================
    // ANDROID LIFECYCLE & UI DEPENDENCIES
    // ==========================================
    
    // Used in sample app (from Ola documentation)
    implementation("androidx.lifecycle:lifecycle-extensions:2.0.0")
    implementation("androidx.lifecycle:lifecycle-compiler:2.0.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.7.0")
    
    // Core Android dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.cardview:cardview:1.0.0")
    
    // ==========================================
    // LOCATION SERVICES
    // ==========================================
    
    // For location tracking during navigation
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("com.google.android.gms:play-services-maps:18.2.0")
    
    // ==========================================
    // ADDITIONAL UTILITIES
    // ==========================================
    
    // For permissions handling
    implementation("androidx.activity:activity-ktx:1.8.2")
    implementation("androidx.fragment:fragment-ktx:1.6.2")
    
    // For multidex support (if needed)
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}