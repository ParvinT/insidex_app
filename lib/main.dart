// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/mini_player_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/download_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/audio/audio_handler.dart';
import 'services/audio/audio_cache_service.dart';
import 'app.dart';
import 'core/constants/app_info.dart';
import 'providers/notification_provider.dart';
import 'package:device_preview/device_preview.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/notification_reliability_service.dart';
import 'services/device_session_service.dart';
import 'services/download/connectivity_service.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  debugPrint('[BackgroundFetch] Headless çalışıyor');

  await Firebase.initializeApp();
  await NotificationReliabilityService.checkAndRescheduleNotifications();

  BackgroundFetch.finish(task.taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.initialize();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // ✅ App Check initialization
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider:
          kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
    );
    debugPrint('✅ Firebase App Check initialized');
  }
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  if (!kIsWeb) {
    // Background Fetch - Optional feature (non-blocking)
    try {
      BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
      debugPrint('✅ Background Fetch initialized ');
    } catch (e) {
      debugPrint('⚠️ Background Fetch unavailable: $e');
    }
  }
  // Notification Service
  try {
    await NotificationService().initialize();
    debugPrint('Notification Service initialized successfully');
  } catch (e) {
    debugPrint('Notification Service initialization error: $e');
  }

  try {
    DeviceSessionService().initializeTokenRefreshListener();
    debugPrint('FCM Token Refresh Listener initialized');
  } catch (e) {
    debugPrint('FCM Token Refresh error: $e');
  }

  try {
    await AudioCacheService.initialize();
    debugPrint('✅ Audio Cache initialized');
    await initAudioService();
    debugPrint('✅ Audio Service initialized successfully');
  } catch (e) {
    debugPrint('❌ Audio Service initialization error: $e');
  }

  try {
    await ConnectivityService().initialize();
    debugPrint('✅ Connectivity Service initialized');
  } catch (e) {
    debugPrint('Connectivity Service initialization error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  debugPrint('🌍 Initializing LocaleProvider...');
  final localeProvider = await LocaleProvider.initialize();
  debugPrint(
      '✅ LocaleProvider ready with locale: ${localeProvider.locale.languageCode}');

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DownloadProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
              create: (_) => UserProvider()..initAuthListener()),
          ChangeNotifierProvider(
              create: (_) => NotificationProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => MiniPlayerProvider()),
          ChangeNotifierProvider(
            create: (_) => SubscriptionProvider(),
            lazy: false,
          ),
        ],
        child: InsidexApp(localeProvider: localeProvider),
      ),
    ),
  );
}
