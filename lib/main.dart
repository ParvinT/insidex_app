// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/audio_player_service.dart';
import 'app.dart';
import 'providers/notification_provider.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/notification_reliability_service.dart';
import 'services/device_session_service.dart';
import 'providers/locale_provider.dart';
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

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    await NotificationReliabilityService.initialize();
  }
  // Notification Service
  try {
    await NotificationService().initialize();
    print('Notification Service initialized successfully');
  } catch (e) {
    print('Notification Service initialization error: $e');
  }

  try {
    DeviceSessionService().initializeTokenRefreshListener();
    print('FCM Token Refresh Listener initialized');
  } catch (e) {
    print('FCM Token Refresh error: $e');
  }

  // Audio Service'i başlat - Basit versiyon
  try {
    await AudioPlayerService().initialize();
    print('Audio Service initialized successfully');
  } catch (e) {
    print('Audio Service initialization error: $e');
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(
            create: (_) => UserProvider()..initAuthListener()),
        ChangeNotifierProvider(
            create: (_) => NotificationProvider()..initialize()),
      ],
      child: const InsidexApp(),
    ),
  );
}
