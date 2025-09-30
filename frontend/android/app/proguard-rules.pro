# Opening move: ProGuard rules for Flutter release builds
# These rules ensure Flutter and Firebase work correctly with code shrinking enabled

# Keep Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Main play: Keep Play Core library classes (required for Flutter's deferred components)
# Flutter references these classes even if we don't use Play Store features
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Main play: Keep Firebase classes from being obfuscated
# Firebase uses reflection extensively, so we need to preserve class names
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Google Play Services
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }

# Time to tackle the tricky bit: Keep model classes for Firebase/JSON serialization
# Add your Dart model classes here if you use them with Firebase or JSON
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Victory lap: Keep native methods (JNI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
