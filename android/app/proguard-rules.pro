# ===== INSIDEX APP - PROGUARD RULES =====
# AGP 8.x + R8 için optimize edilmiş kurallar

-keep class io.flutter.plugins.** { *; }
-keep class com.baseflow.** { *; }  # permission_handler
-keep class com.ryanheise.** { *; }  # just_audio & audio_service
-keep class io.flutter.plugins.firebase.** { *; }  # tüm firebase plugin'leri

# ===== 1. GOOGLE PLAY CORE (Missing classes fix) =====
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# ===== 2. FLUTTER CORE =====
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# ===== 3. NOTIFICATION SYSTEM (EN KRİTİK!) =====
# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { 
    <fields>;
    <methods>;
}

# Scheduled Notifications (ARKA PLAN İÇİN!)
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin { *; }
-keep class com.dexterous.flutterlocalnotifications.ForegroundService { *; }

# ===== 4. BACKGROUND FETCH (6 saatte bir kontrol) =====
-keep class com.transistorsoft.tsbackgroundfetch.** { *; }
-keep interface com.transistorsoft.tsbackgroundfetch.** { *; }

# ===== 5. ANDROID SYSTEM CLASSES =====
# Notifications
-keep class android.app.Notification** { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# Alarm Manager (zamanlama için)
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

# Broadcast Receivers
-keep public class * extends android.content.BroadcastReceiver {
    public void onReceive(android.content.Context, android.content.Intent);
}
-keep public class * extends android.app.Service
-keep public class * extends android.app.Activity

# ===== 6. TIMEZONE (bildirim zamanlaması için) =====
-keep class com.flutter.timezone.** { *; }
-keep class org.joda.time.** { *; }
-dontwarn org.joda.time.**

# ===== 7. FIREBASE =====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# ===== 8. WORKMANAGER =====
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }

# ===== 9. SHARED PREFERENCES (ayarlar için) =====
-keep class androidx.preference.** { *; }

# ===== 10. REFLECTION & ANNOTATIONS =====
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ===== 11. R8 AYARLARI =====
-ignorewarnings
-dontwarn **

# Debug için (production'da kaldırabilirsin)
-dontobfuscate