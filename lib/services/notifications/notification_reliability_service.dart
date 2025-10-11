import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';
import 'daily_reminder_service.dart';
import 'notification_service.dart';
import '../../features/notifications/notification_models.dart';

class NotificationReliabilityService {
  static const String _lastCheckKey = "last_notification_check";
  static const String _settingsPrefix = "notification_settings_";

  /// Background Fetch'i başlat
  static Future<void> initialize() async {
    debugPrint('🚀 Background Fetch başlatılıyor...');

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 360, // 6 saat (dakika olarak)
        stopOnTerminate: false, // Uygulama kapansa bile çalış
        startOnBoot: true, // Telefon açılınca başla
        enableHeadless: true, // Arka planda çalış
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    debugPrint('✅ Background Fetch başarıyla kuruldu');
  }

  /// Arka planda çalışacak fonksiyon
  static void _onBackgroundFetch(String taskId) async {
    debugPrint('🔔 Arka plan görevi çalışıyor: $taskId');

    await checkAndRescheduleNotifications();

    BackgroundFetch.finish(taskId); // Görevi bitir
  }

  /// Timeout durumunda
  static void _onBackgroundFetchTimeout(String taskId) {
    debugPrint('⏱️ Görev zaman aşımı: $taskId');
    BackgroundFetch.finish(taskId);
  }

  /// Bildirimleri kontrol et ve yeniden planla
  static Future<void> checkAndRescheduleNotifications() async {
    debugPrint('🔍 Bildirimler kontrol ediliyor...');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Son kontrolden 30 dakika geçmemişse atla
      final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastCheck < 1800000 && lastCheck > 0) {
        debugPrint('⏭️ Çok yakın zamanda kontrol edildi, atlanıyor');
        return;
      }

      // Bildirim servisini başlat
      final notificationService = NotificationService();
      await notificationService.initialize();

      // İzin var mı?
      final hasPermission = await notificationService.hasPermission();
      if (!hasPermission) {
        debugPrint('❌ Bildirim izni yok');
        return;
      }

      // Mevcut bildirimleri kontrol et
      final pending = await notificationService.getPendingNotifications();
      final hasDailyReminder =
          pending.any((p) => p.id == NotificationConstants.dailyReminderId);

      // Daily reminder yoksa yeniden planla
      if (!hasDailyReminder) {
        debugPrint('⚠️ Daily reminder bulunamadı - yeniden planlanıyor');

        final settings = await _loadNotificationSettings();
        if (settings != null && settings.dailyReminder.enabled) {
          await DailyReminderService()
              .scheduleDailyReminder(settings.dailyReminder);
          debugPrint('✅ Daily reminder yeniden planlandı');
        }
      } else {
        debugPrint('✅ Daily reminder zaten mevcut');
      }

      await prefs.setInt(_lastCheckKey, now);
    } catch (e) {
      debugPrint('❌ Hata: $e');
    }
  }

  /// Ayarları yükle
  static Future<NotificationSettings?> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool('${_settingsPrefix}enabled') ?? false;
    final hour = prefs.getInt('${_settingsPrefix}hour') ?? 21;
    final minute = prefs.getInt('${_settingsPrefix}minute') ?? 0;

    if (!enabled) return null;

    return NotificationSettings(
      allNotificationsEnabled: true,
      dailyReminder: DailyReminder(
        enabled: enabled,
        scheduledTime: DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          hour,
          minute,
        ),
        title: 'Time for Your Daily Session 🎵',
        message: 'Take a moment for yourself with INSIDEX',
      ),
      lastUpdated: DateTime.now(),
    );
  }

  /// Ayarları kaydet
  static Future<void> saveSettings(DailyReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_settingsPrefix}enabled', reminder.enabled);
    await prefs.setInt('${_settingsPrefix}hour', reminder.scheduledTime.hour);
    await prefs.setInt(
        '${_settingsPrefix}minute', reminder.scheduledTime.minute);
    await prefs.setString('${_settingsPrefix}title', reminder.title);
    await prefs.setString('${_settingsPrefix}message', reminder.message);

    debugPrint('💾 Ayarlar kaydedildi');
  }
}
