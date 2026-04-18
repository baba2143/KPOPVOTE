# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Kotlinx Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keep,includedescriptorclasses class com.kpopvote.collector.**$$serializer { *; }
-keepclassmembers class com.kpopvote.collector.** {
    *** Companion;
}
-keepclasseswithmembers class com.kpopvote.collector.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Compose
-keep class androidx.compose.** { *; }

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Keep enums used in serialization
-keepclassmembers enum * { *; }

# Timber
-dontwarn org.jetbrains.annotations.**

# R8 full mode
-allowaccessmodification
-dontusemixedcaseclassnames
