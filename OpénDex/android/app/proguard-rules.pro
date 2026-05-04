# Flutter-specific: don't shrink or obfuscate (Flutter's asset handling needs stable class names)
-dontoptimize
-dontobfuscate

# Keep google_generative_ai / http package classes (DNS, TLS, networking)
-keep class com.google.api.** { *; }
-keep class com.google.common.** { *; }
-keep class com.google.protobuf.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn java.security.**

# Keep Google AI / Generative AI SDK
-keep class com.google.ai.client.generativeai.** { *; }
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**

# Keep dart:io related classes from being stripped by R8
-keep class java.net.** { *; }
-keep class java.nio.** { *; }
-keep class sun.net.** { *; }
-keep class com.android.org.conscrypt.** { *; }
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ---- google_fonts ProGuard Rules ----
# Keep all GoogleFonts styles and generated style classes
-keep class com.google.** { *; }
-keep class ** extends com.google.fonts.GoogleFontStyle { *; }
-keep enum com.google.fonts.GoogleFontStyle { *; }
-keep class sun.misc.Unsafe { *; }
-dontwarn sun.misc.Unsafe**

# ---- End google_fonts ProGuard Rules ----

# Preserve JSON parsing types
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep shared_preferences storage implementation
-keep class android.content.SharedPreferences { *; }

# Keep Dart-generated platform channels
-keep class io.flutter.plugins.** { *; }
