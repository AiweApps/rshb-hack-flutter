plugins {
    id("com.android.library")
    id("com.chaquo.python") version "17.1.0"
}

android {
    namespace = "com.aiweapps.winescan.local.runtime"
    compileSdk = 36
    defaultConfig {
        minSdk = 29
        consumerProguardFiles("consumer-rules.pro")
        ndk { abiFilters += "arm64-v8a" }
    }
    sourceSets.getByName("main") {
        kotlin.srcDir("runtime/kotlin")
        assets.srcDir("../../external/android/bundle-assets-v2")
        jniLibs.srcDir("../../external/android/jniLibs")
    }
    packaging { jniLibs.useLegacyPackaging = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}


chaquopy {
    defaultConfig {
        version = "3.12"
        buildPython(providers.environmentVariable("WINE_BUILD_PYTHON").getOrElse("python3.12"))
        pip {
            install("numpy==1.26.2")
            install("Pillow==11.0.0")
            install("cloudpickle==3.1.2")
        }
        pyc { src = false }
    }
    sourceSets.getByName("main") { srcDir("runtime/python") }
}

dependencies {
    implementation("com.microsoft.onnxruntime:onnxruntime-android:1.23.2")
}
