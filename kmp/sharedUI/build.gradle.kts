import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidMultiplatformLibrary)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
}

kotlin {

    listOf(
        iosArm64(),
        iosSimulatorArm64()
    ).forEach { iosTarget ->
        iosTarget.binaries.framework {
            baseName = "SharedLogic"
            isStatic = true
            export(projects.sharedLogic)
            export(projects.core)
            export(libs.decompose)
            export(libs.essenty.lifecycle)
            export(libs.essenty.lifecycle.coroutines)
        }
    }

    androidLibrary {
       namespace = "com.aiweapps.winescan.sharedUI"
       compileSdk = libs.versions.android.compileSdk.get().toInt()
       minSdk = libs.versions.android.minSdk.get().toInt()
    
       compilerOptions {
           jvmTarget = JvmTarget.JVM_11
       }
       androidResources {
           enable = true
       }
       withHostTest {
           isIncludeAndroidResources = true
       }
    }
    
    sourceSets {
        androidMain.dependencies {
            implementation(libs.compose.uiToolingPreview)
        }
        commonMain.dependencies {
            api(projects.sharedLogic)
            api(projects.core)
            api(projects.sharedUIKit)
            implementation(libs.koin.compose)
            api(libs.decompose)
            implementation(libs.decompose.extensions.compose)
            api(libs.essenty.lifecycle)
            api(libs.essenty.lifecycle.coroutines)
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.material.icons.extended)
            implementation(libs.compose.ui)
            // api, not implementation: with publicResClass the generated Res object is part
            // of this module's public surface, and StringResource appears in its signatures.
            api(libs.compose.components.resources)
            implementation(libs.compose.uiToolingPreview)
            implementation(libs.androidx.lifecycle.viewmodelCompose)
            implementation(libs.androidx.lifecycle.runtimeCompose)
        }
        commonTest.dependencies {
            implementation(libs.kotlin.test)
        }
    }
}

// Generated resource accessors are internal by default, which makes them unusable from
// :androidApp. Shared strings such as the error wording and the retry label are rendered by
// native Android screens too, and duplicating them into androidApp/res would give the same
// text two sources that drift apart. Exposing the generated class keeps one catalogue.
compose.resources {
    publicResClass = true
    packageOfResClass = "winescan.sharedui.generated.resources"
    generateResClass = auto
}

dependencies {
    androidRuntimeClasspath(libs.compose.uiTooling)
}
