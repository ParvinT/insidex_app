// lib/services/daily_quote_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';

/// Service for managing daily motivational quotes
/// Uses aggressive caching to minimize Firebase reads
class DailyQuoteService {
  static final DailyQuoteService _instance = DailyQuoteService._internal();
  factory DailyQuoteService() => _instance;
  DailyQuoteService._internal();

  // Cache keys
  static const String _cacheKey = 'daily_quotes_cache';
  static const String _cacheTimestampKey = 'daily_quotes_timestamp';
  static const String _selectedQuoteKey = 'daily_quote_selected';
  static const String _selectedDateKey = 'daily_quote_date';

  // Cache duration: 7 days
  static const int _cacheDurationDays = 7;

  // In-memory cache
  List<QuoteModel>? _quotesCache;
  // =================== PUBLIC API ===================

  /// Get all quotes (cache-first strategy)
  Future<List<QuoteModel>> getQuotes({bool forceRefresh = false}) async {
    // Return in-memory cache if available and not forcing refresh
    if (!forceRefresh && _quotesCache != null && _quotesCache!.isNotEmpty) {
      debugPrint('📦 [DailyQuote] Using in-memory cache');
      return _quotesCache!;
    }

    final prefs = await SharedPreferences.getInstance();

    // Check local cache validity
    if (!forceRefresh && await _isCacheValid(prefs)) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('📦 [DailyQuote] Using SharedPreferences cache');
        _quotesCache = _parseQuotes(cachedData);
        return _quotesCache!;
      }
    }

    // Fetch from Firebase
    try {
      final quotes = await _fetchFromFirebase();

      if (quotes.isNotEmpty) {
        // Save to cache
        await _saveToCache(prefs, quotes);
        _quotesCache = quotes;
        debugPrint(
            '☁️ [DailyQuote] Fetched ${quotes.length} quotes from Firebase');
        return quotes;
      }
    } catch (e) {
      debugPrint('⚠️ [DailyQuote] Firebase fetch failed: $e');
    }

    // Fallback to expired cache if available
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      debugPrint('⚠️ [DailyQuote] Using expired cache as fallback');
      _quotesCache = _parseQuotes(cachedData);
      return _quotesCache!;
    }

    // Return empty list if nothing available
    debugPrint('❌ [DailyQuote] No quotes available');
    return [];
  }

  /// Get today's quote (smart selection based on context)
  Future<QuoteModel?> getTodayQuote({
    required List<String> userGoals,
    required int streak,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();

    // Check if we already selected a quote for today
    final savedDate = prefs.getString(_selectedDateKey);
    if (savedDate == today) {
      final savedQuoteJson = prefs.getString(_selectedQuoteKey);
      if (savedQuoteJson != null && savedQuoteJson.isNotEmpty) {
        try {
          final quoteMap = jsonDecode(savedQuoteJson) as Map<String, dynamic>;
          debugPrint('📦 [DailyQuote] Using today\'s cached quote');
          return QuoteModel.fromMap(quoteMap);
        } catch (e) {
          debugPrint('⚠️ [DailyQuote] Error parsing cached quote: $e');
        }
      }
    }

    // Select new quote for today
    final quotes = await getQuotes();
    if (quotes.isEmpty) return null;

    final selectedQuote = _selectSmartQuote(
      quotes: quotes,
      userGoals: userGoals,
      streak: streak,
    );

    // Save selection for today
    if (selectedQuote != null) {
      await prefs.setString(_selectedDateKey, today);
      await prefs.setString(
          _selectedQuoteKey, jsonEncode(selectedQuote.toMap()));
      debugPrint(
          '✨ [DailyQuote] Selected new quote for today: ${selectedQuote.id}');
    }

    return selectedQuote;
  }

  /// Force refresh quotes from Firebase
  Future<void> refreshQuotes() async {
    await getQuotes(forceRefresh: true);
  }

  /// Clear all cached quotes
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_selectedQuoteKey);
    await prefs.remove(_selectedDateKey);
    _quotesCache = null;
    debugPrint('🧹 [DailyQuote] Cache cleared');
  }

  // =================== SMART QUOTE SELECTION ===================

  QuoteModel? _selectSmartQuote({
    required List<QuoteModel> quotes,
    required List<String> userGoals,
    required int streak,
  }) {
    if (quotes.isEmpty) return null;

    final hour = DateTime.now().hour;
    final timeCategory = _getTimeCategory(hour);

    // Score each quote
    final scoredQuotes = quotes.map((quote) {
      int score = 0;

      // Time category match (+3 points)
      if (quote.matchesTimeCategory(timeCategory)) {
        score += 3;
      }

      // Goal match (+2 points per matching goal)
      for (var goal in userGoals) {
        if (quote.targetGoals.contains(goal)) {
          score += 2;
        }
      }

      // General quotes get base score (+1)
      if (quote.categories.contains('general') || quote.categories.isEmpty) {
        score += 1;
      }

      // Streak-based bonus
      if (streak == 0 && quote.categories.contains('motivation')) {
        score += 2; // Encourage users who lost streak
      } else if (streak >= 7 && quote.categories.contains('achievement')) {
        score += 2; // Celebrate consistent users
      }

      return MapEntry(quote, score);
    }).toList();

    // Sort by score (descending)
    scoredQuotes.sort((a, b) => b.value.compareTo(a.value));

    // Use day of year for consistent daily selection from top candidates
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;

    // Pick from top 5 based on day (for variety while maintaining relevance)
    final topQuotes = scoredQuotes.take(5).toList();
    final selectedIndex = dayOfYear % topQuotes.length;

    return topQuotes[selectedIndex].key;
  }

  String _getTimeCategory(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 17) {
      return 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  // =================== GREETING HELPER ===================

  /// Get time-based greeting
  static String getGreeting(String? userName, String locale) {
    final hour = DateTime.now().hour;
    final name = userName ?? '';
    final hasName = name.isNotEmpty;

    String greeting;
    String emoji;

    if (hour >= 5 && hour < 12) {
      emoji = '☀️';
      greeting = _getLocalizedGreeting('morning', locale);
    } else if (hour >= 12 && hour < 17) {
      emoji = '🌤️';
      greeting = _getLocalizedGreeting('afternoon', locale);
    } else if (hour >= 17 && hour < 22) {
      emoji = '🌆';
      greeting = _getLocalizedGreeting('evening', locale);
    } else {
      emoji = '🌙';
      greeting = _getLocalizedGreeting('night', locale);
    }

    if (hasName) {
      return '$emoji $greeting, $name!';
    }
    return '$emoji $greeting!';
  }

  static String _getLocalizedGreeting(String timeOfDay, String locale) {
    final greetings = {
      'morning': {
        'en': 'Good morning',
        'tr': 'Günaydın',
        'ru': 'Доброе утро',
        'hi': 'सुप्रभात',
      },
      'afternoon': {
        'en': 'Good afternoon',
        'tr': 'İyi günler',
        'ru': 'Добрый день',
        'hi': 'नमस्ते',
      },
      'evening': {
        'en': 'Good evening',
        'tr': 'İyi akşamlar',
        'ru': 'Добрый вечер',
        'hi': 'शुभ संध्या',
      },
      'night': {
        'en': 'Good night',
        'tr': 'İyi geceler',
        'ru': 'Доброй ночи',
        'hi': 'शुभ रात्रि',
      },
    };

    return greetings[timeOfDay]?[locale] ??
        greetings[timeOfDay]?['en'] ??
        'Hello';
  }

  // =================== CACHE MANAGEMENT ===================

  Future<bool> _isCacheValid(SharedPreferences prefs) async {
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    const maxAge = _cacheDurationDays * 24 * 60 * 60 * 1000;

    return cacheAge < maxAge;
  }

  Future<void> _saveToCache(
      SharedPreferences prefs, List<QuoteModel> quotes) async {
    try {
      final quotesJson = quotes.map((q) => q.toMap()).toList();
      await prefs.setString(_cacheKey, jsonEncode(quotesJson));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 [DailyQuote] Saved ${quotes.length} quotes to cache');
    } catch (e) {
      debugPrint('❌ [DailyQuote] Error saving to cache: $e');
    }
  }

  List<QuoteModel> _parseQuotes(String jsonString) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => QuoteModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('❌ [DailyQuote] Error parsing quotes: $e');
      return [];
    }
  }

  // =================== FIREBASE ===================

  Future<List<QuoteModel>> _fetchFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('daily_quotes')
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ [DailyQuote] No quotes document in Firebase');
        return [];
      }

      final data = doc.data()!;
      final quotesData = data['quotes'] as List<dynamic>? ?? [];

      final quotes = quotesData
          .map((item) => QuoteModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      return quotes;
    } catch (e) {
      debugPrint('❌ [DailyQuote] Firebase fetch error: $e');
      return [];
    }
  }

  // =================== HELPERS ===================

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
