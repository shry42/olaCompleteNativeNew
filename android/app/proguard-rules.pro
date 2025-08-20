# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Keep Ola Maps classes
-keep class com.ola.mapsdk.** { *; }
-keep class org.maplibre.** { *; }
-dontwarn com.ola.mapsdk.**
-dontwarn org.maplibre.**

# Keep location services
-keep class com.google.android.gms.location.** { *; }

# Keep JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }