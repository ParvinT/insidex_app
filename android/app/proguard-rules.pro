# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.* { *; }
-keep class io.flutter.embedding.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Local Notifications - KRİTİK!
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep interface com.dexterous.** { *; }
-keep enum com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }
-keepattributes *Annotation*

# Android System Classes
-keep class android.app.** { *; }
-keep class android.content.** { *; }
-keep class androidx.** { *; }
-keepclassmembers class androidx.** { *; }

# Timezone - ÇOK ÖNEMLİ!
-keep class org.joda.time.** { *; }
-keep interface org.joda.time.** { *; }
-keep class com.flutter.timezone.** { *; }
-dontwarn org.joda.time.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes Exceptions

# Reflection kullanan class'lar için
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enum'lar için
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Broadcast Receivers - SÜPER KRİTİK!
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Service
-keep public class * extends android.app.Activity

# Notification specific
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationChannelGroup { *; }
-keep class android.app.Notification { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.service.notification.** { *; }

# PendingIntent
-keep class android.app.PendingIntent { *; }
-keep class android.content.Intent { *; }

# AlarmManager
-keep class android.app.AlarmManager { *; }
-keep class android.app.AlarmManager$* { *; }

# PowerManager
-keep class android.os.PowerManager { *; }
-keep class android.os.PowerManager$* { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.**

# Android support media (gerekirse)
-keep class android.support.v4.media.** { *; }

# Flutter Local Notifications Plugin specific classes
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ForegroundService { *; }