# R8 rules for the release build.
#
# Every rule below exists because something in this stack resolves types by name at
# runtime, which R8 cannot see. Removing a rule "because the build still passes" is not a
# valid check: these fail at runtime, not at build time.

# --- kotlinx.serialization ---------------------------------------------------------------
# Serializers are generated as nested classes and looked up reflectively by the plugin's
# runtime. Keeping the annotation and the companion is what makes @Serializable survive.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class ** {
    public static ** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
    public static ** INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}

# DTOs and states are deserialized by name — their fields must keep their names.
-keepclassmembers @kotlinx.serialization.Serializable class ** {
    <fields>;
}

# --- Ktor --------------------------------------------------------------------------------
# Engines and plugins are discovered through service loading and reflection.
-keep class io.ktor.** { *; }
-keepclassmembers class io.ktor.** { volatile <fields>; }
-dontwarn io.ktor.**
-dontwarn org.slf4j.**

# --- OkHttp (Ktor's Android engine) -------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**

# --- Room --------------------------------------------------------------------------------
# Generated *_Impl classes are instantiated by name.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep @androidx.room.Entity class * { *; }
-dontwarn androidx.room.paging.**

# --- Koin --------------------------------------------------------------------------------
# Definitions are resolved by KClass, so the constructors being injected must stay.
-keepclassmembers class * {
    public <init>(...);
}
-dontwarn org.koin.**

# --- Decompose / Essenty ------------------------------------------------------------------
# Navigation configurations are @Serializable and restored by name after process death.
-keep class com.arkivanov.** { *; }
-dontwarn com.arkivanov.**

# --- Coroutines ---------------------------------------------------------------------------
-dontwarn kotlinx.coroutines.**
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }

# --- Firebase Crashlytics ------------------------------------------------------------------
# Line numbers and exception class names are what make an obfuscated crash report readable
# after the mapping file is applied.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# --- App ----------------------------------------------------------------------------------
# Navigation configs and screen states are serialized by kotlinx-serialization; their
# names are part of the saved payload.
-keep @kotlinx.serialization.Serializable class com.aiweapps.** { *; }
