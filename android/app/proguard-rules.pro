# Jangan hapus class-model (ubah sesuai package kamu)
-keep class com.example.tubes_mobile.models.** { *; }
-keepclassmembers class com.example.tubes_mobile.models.** { *; }

# Jangan obfuscate semua class
-dontshrink
-dontobfuscate
-dontoptimize

# Flutter & plugin keep rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Untuk Play Core (biar ga missing kayak error R8 sebelumnya)
-keep class com.google.android.play.core.** { *; }

# Gson / JSON parsing
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends java.lang.annotation.Annotation { *; }
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Material Icons
-keep class androidx.** { *; }
