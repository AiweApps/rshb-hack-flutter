import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Properties

val wineAssistantLocal = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.isFile) file.inputStream().use(::load)
}

fun assistantProperty(name: String): String =
    providers.gradleProperty(name).orNull
        ?: providers.environmentVariable(name).orNull
        ?: wineAssistantLocal.getProperty(name).orEmpty()

fun quotedBuildValue(value: String): String =
    "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
    alias(libs.plugins.googleServices)
    alias(libs.plugins.firebaseCrashlytics)
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}
dependencies {
    implementation(projects.sharedUI)
    implementation(project(":scannerLocalAndroid"))

    implementation(libs.koin.android)
    implementation(libs.androidx.activity.compose)
    implementation(libs.decompose.extensions.compose)

    implementation(libs.compose.runtime)
    implementation(libs.compose.foundation)
    implementation(libs.compose.material3)
    implementation(libs.compose.material.icons.extended)
    implementation(libs.compose.ui)
    implementation(libs.haze)
    implementation(libs.compose.uiToolingPreview)
    implementation(libs.coil.compose)
    implementation(libs.coil.network.ktor)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.material)
    implementation(libs.camerax.core)
    implementation(libs.camerax.camera2)
    implementation(libs.camerax.lifecycle)
    implementation(libs.camerax.view)
    implementation(libs.androidx.exifinterface)
    // HistoryDaySection.day is a kotlinx.datetime.LocalDate, so the type must be on this classpath.
    implementation(libs.kotlinx.datetime)
    implementation(libs.kotlinx.coroutines.core)
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.analytics)
    implementation(libs.firebase.crashlytics)
    debugImplementation(libs.compose.uiTooling)
}

android {
    namespace = "com.aiweapps.winescan"
    compileSdk = libs.versions.android.compileSdk.get().toInt()

    defaultConfig {
        applicationId = "com.aiweapps.winescan"
        minSdk = libs.versions.android.minSdk.get().toInt()
        targetSdk = libs.versions.android.targetSdk.get().toInt()
        versionCode = 1
        versionName = "1.0.0"
    }
    sourceSets.getByName("main").kotlin.srcDir("../integrations/ondevice_android/runtime/kmm")
    sourceSets.getByName("main").res.srcDir("../integrations/ondevice_android/runtime/res")
    packaging.jniLibs.useLegacyPackaging = true
    buildFeatures {
        // DemoApp reads BuildConfig.DEBUG to build the shared AppConfig.
        buildConfig = true
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    buildTypes {
        getByName("debug") {
            buildConfigField("String", "ASSISTANT_BASE_URL", quotedBuildValue(assistantProperty("WINE_ASSISTANT_BASE_URL")))
            buildConfigField("String", "ASSISTANT_TOKEN", quotedBuildValue(""))
        }
        getByName("release") {
            buildConfigField("String", "ASSISTANT_BASE_URL", quotedBuildValue(""))
            buildConfigField("String", "ASSISTANT_TOKEN", quotedBuildValue(""))
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

// Firebase configuration is supplied privately. A local debug build remains usable
// without it; release processing still requires the real project configuration.
tasks.matching { it.name == "processDebugGoogleServices" }.configureEach {
    enabled = file("google-services.json").isFile
}
