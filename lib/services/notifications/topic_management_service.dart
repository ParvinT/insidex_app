// lib/services/notifications/topic_management_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages FCM topic subscriptions for push notifications.
///
/// Topics are used to segment users for targeted notifications:
/// - all_users: Every registered user
/// - lang_{code}: Language-based (en, tr, ru, hi)
/// - tier_{name}: Subscription tier (free, lite, standard)
/// - platform_{os}: Platform-based (ios, android)
///
/// Usage:
/// ```dart
/// // On login/register
/// await TopicManagementService().subscribeUserTopics(
///   language: 'tr',
///   tier: 'free',
/// );
///
/// // On language change
/// await TopicManagementService().updateLanguageTopic('en');
///
/// // On subscription change
/// await TopicManagementService().updateTierTopic('standard');
///
/// // On logout
/// await TopicManagementService().unsubscribeAllTopics();
/// ```
class TopicManagementService {
  static final TopicManagementService _instance =
      TopicManagementService._internal();
  factory TopicManagementService() => _instance;
  TopicManagementService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // SharedPreferences keys for tracking active topics
  static const String _keyLanguageTopic = 'fcm_topic_language';
  static const String _keyTierTopic = 'fcm_topic_tier';
  static const String _keyPlatformTopic = 'fcm_topic_platform';
  static const String _keyAllUsersTopic = 'fcm_topic_all_users';
  static const String _keyTopicsInitialized = 'fcm_topics_initialized';

  // Topic prefixes
  static const String _topicAllUsers = 'all_users';
  static const String _prefixLang = 'lang_';
  static const String _prefixTier = 'tier_';
  static const String _prefixPlatform = 'platform_';

  // Valid values
  static const List<String> _validLanguages = ['en', 'tr', 'ru', 'hi'];
  static const List<String> _validTiers = ['free', 'lite', 'standard'];

  /// Subscribe user to all relevant topics on login/register.
  ///
  /// [language] - User's preferred language code (en, tr, ru, hi)
  /// [tier] - User's subscription tier (free, lite, standard)
  Future<void> subscribeUserTopics({
    required String language,
    required String tier,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Subscribe to all_users
      await _safeSubscribe(_topicAllUsers);
      await prefs.setBool(_keyAllUsersTopic, true);

      // 2. Subscribe to language topic
      final langTopic = _buildLanguageTopic(language);
      if (langTopic != null) {
        await _safeSubscribe(langTopic);
        await prefs.setString(_keyLanguageTopic, langTopic);
      }

      // 3. Subscribe to tier topic
      final tierTopic = _buildTierTopic(tier);
      if (tierTopic != null) {
        await _safeSubscribe(tierTopic);
        await prefs.setString(_keyTierTopic, tierTopic);
      }

      // 4. Subscribe to platform topic
      final platformTopic = _buildPlatformTopic();
      await _safeSubscribe(platformTopic);
      await prefs.setString(_keyPlatformTopic, platformTopic);

      // Mark as initialized
      await prefs.setBool(_keyTopicsInitialized, true);

      debugPrint('✅ [TopicManager] Subscribed: '
          '$_topicAllUsers, $langTopic, $tierTopic, $platformTopic');
    } catch (e) {
      debugPrint('❌ [TopicManager] Error subscribing topics: $e');
    }
  }

  /// Update language topic when user changes language.
  ///
  /// Unsubscribes from old language topic and subscribes to new one.
  Future<void> updateLanguageTopic(String newLanguage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_keyTopicsInitialized) ?? false;

      if (!isInitialized) {
        debugPrint('⚠️ [TopicManager] Topics not initialized, skipping language update');
        return;
      }

      // Unsubscribe from old language topic
      final oldTopic = prefs.getString(_keyLanguageTopic);
      if (oldTopic != null) {
        await _safeUnsubscribe(oldTopic);
      }

      // Subscribe to new language topic
      final newTopic = _buildLanguageTopic(newLanguage);
      if (newTopic != null) {
        await _safeSubscribe(newTopic);
        await prefs.setString(_keyLanguageTopic, newTopic);
      }

      debugPrint('✅ [TopicManager] Language topic updated: $oldTopic → $newTopic');
    } catch (e) {
      debugPrint('❌ [TopicManager] Error updating language topic: $e');
    }
  }

  /// Update tier topic when subscription changes.
  ///
  /// Unsubscribes from old tier topic and subscribes to new one.
  Future<void> updateTierTopic(String newTier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool(_keyTopicsInitialized) ?? false;

      if (!isInitialized) {
        debugPrint('⚠️ [TopicManager] Topics not initialized, skipping tier update');
        return;
      }

      // Unsubscribe from old tier topic
      final oldTopic = prefs.getString(_keyTierTopic);
      if (oldTopic != null) {
        await _safeUnsubscribe(oldTopic);
      }

      // Subscribe to new tier topic
      final newTopic = _buildTierTopic(newTier);
      if (newTopic != null) {
        await _safeSubscribe(newTopic);
        await prefs.setString(_keyTierTopic, newTopic);
      }

      debugPrint('✅ [TopicManager] Tier topic updated: $oldTopic → $newTopic');
    } catch (e) {
      debugPrint('❌ [TopicManager] Error updating tier topic: $e');
    }
  }

  /// Unsubscribe from all topics on logout.
  ///
  /// Cleans up all topic subscriptions and resets local state.
  Future<void> unsubscribeAllTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Unsubscribe from all_users
      if (prefs.getBool(_keyAllUsersTopic) ?? false) {
        await _safeUnsubscribe(_topicAllUsers);
      }

      // Unsubscribe from language topic
      final langTopic = prefs.getString(_keyLanguageTopic);
      if (langTopic != null) {
        await _safeUnsubscribe(langTopic);
      }

      // Unsubscribe from tier topic
      final tierTopic = prefs.getString(_keyTierTopic);
      if (tierTopic != null) {
        await _safeUnsubscribe(tierTopic);
      }

      // Unsubscribe from platform topic
      final platformTopic = prefs.getString(_keyPlatformTopic);
      if (platformTopic != null) {
        await _safeUnsubscribe(platformTopic);
      }

      // Clear all stored topic state
      await prefs.remove(_keyAllUsersTopic);
      await prefs.remove(_keyLanguageTopic);
      await prefs.remove(_keyTierTopic);
      await prefs.remove(_keyPlatformTopic);
      await prefs.remove(_keyTopicsInitialized);

      debugPrint('✅ [TopicManager] All topics unsubscribed and state cleared');
    } catch (e) {
      debugPrint('❌ [TopicManager] Error unsubscribing all topics: $e');
    }
  }

  /// Get list of currently subscribed topics (for debugging/display).
  Future<List<String>> getActiveTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final topics = <String>[];

    if (prefs.getBool(_keyAllUsersTopic) ?? false) {
      topics.add(_topicAllUsers);
    }

    final langTopic = prefs.getString(_keyLanguageTopic);
    if (langTopic != null) topics.add(langTopic);

    final tierTopic = prefs.getString(_keyTierTopic);
    if (tierTopic != null) topics.add(tierTopic);

    final platformTopic = prefs.getString(_keyPlatformTopic);
    if (platformTopic != null) topics.add(platformTopic);

    return topics;
  }

  /// Check if topics have been initialized for current session.
  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTopicsInitialized) ?? false;
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  String? _buildLanguageTopic(String language) {
    final normalized = language.toLowerCase().trim();
    if (!_validLanguages.contains(normalized)) {
      debugPrint('⚠️ [TopicManager] Invalid language: $language, defaulting to en');
      return '${_prefixLang}en';
    }
    return '$_prefixLang$normalized';
  }

  String? _buildTierTopic(String tier) {
    final normalized = tier.toLowerCase().trim();
    if (!_validTiers.contains(normalized)) {
      debugPrint('⚠️ [TopicManager] Invalid tier: $tier, defaulting to free');
      return '${_prefixTier}free';
    }
    return '$_prefixTier$normalized';
  }

  String _buildPlatformTopic() {
    if (kIsWeb) return '${_prefixPlatform}web';
    return Platform.isIOS
        ? '${_prefixPlatform}ios'
        : '${_prefixPlatform}android';
  }

  Future<void> _safeSubscribe(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('⚠️ [TopicManager] Failed to subscribe to $topic: $e');
    }
  }

  Future<void> _safeUnsubscribe(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('⚠️ [TopicManager] Failed to unsubscribe from $topic: $e');
    }
  }
}