# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Notification Compat
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Timezone
-keep class com.flutter.timezone.** { *; }
-keep class org.joda.time.** { *; }

# Firebase (eğer kullanıyorsanız)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep notification channels
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationChannelGroup { *; }