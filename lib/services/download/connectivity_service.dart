// lib/services/download/connectivity_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
/// Used for offline mode detection and download management
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  // Stream controller for connectivity changes
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  // Current status
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;

  // Subscription to connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Check if currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize the service
  Future<void> initialize() async {
    debugPrint('🌐 [Connectivity] Initializing...');

    // Get initial status
    await _checkConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        debugPrint('❌ [Connectivity] Stream error: $error');
        _updateStatus(ConnectivityStatus.unknown);
      },
    );

    debugPrint('✅ [Connectivity] Initialized - Status: $_currentStatus');
  }

  /// Handle connectivity change events
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    debugPrint('🔄 [Connectivity] Change detected: $results');

    final status = _parseConnectivityResults(results);
    _updateStatus(status);
  }

  /// Check current connectivity
  Future<ConnectivityStatus> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final status = _parseConnectivityResults(results);
      _updateStatus(status);
      return status;
    } catch (e) {
      debugPrint('❌ [Connectivity] Check error: $e');
      _updateStatus(ConnectivityStatus.unknown);
      return ConnectivityStatus.unknown;
    }
  }

  /// Force check connectivity (public method)
  Future<ConnectivityStatus> checkConnectivity() async {
    return await _checkConnectivity();
  }

  /// Parse connectivity results to status
  ConnectivityStatus _parseConnectivityResults(
      List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }

    // Check if any connection is available
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
          return ConnectivityStatus.online;
        case ConnectivityResult.vpn:
          // VPN usually means we have internet
          return ConnectivityStatus.online;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          // These might have internet, check others first
          continue;
        case ConnectivityResult.none:
          continue;
      }
    }

    // If only none or unknown results
    if (results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    return ConnectivityStatus.unknown;
  }

  /// Update status and notify listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_currentStatus != newStatus) {
      final oldStatus = _currentStatus;
      _currentStatus = newStatus;

      debugPrint('🌐 [Connectivity] Status changed: $oldStatus → $newStatus');

      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }

  /// Wait for connectivity (with timeout)
  Future<bool> waitForConnectivity({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOnline) return true;

    try {
      await statusStream
          .where((status) => status == ConnectivityStatus.online)
          .first
          .timeout(timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Execute action when online (or immediately if already online)
  Future<T?> executeWhenOnline<T>(
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isOnline) {
      return await action();
    }

    final connected = await waitForConnectivity(timeout: timeout);
    if (connected) {
      return await action();
    }

    return null;
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    debugPrint('🌐 [Connectivity] Disposed');
  }
}

/// Connectivity status enum
enum ConnectivityStatus {
  online,
  offline,
  unknown;

  @override
  String toString() {
    switch (this) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Mixin for widgets that need connectivity awareness
mixin ConnectivityAwareMixin {
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// Start listening to connectivity changes
  void startConnectivityListener(
    void Function(ConnectivityStatus status) onStatusChanged,
  ) {
    _connectivitySubscription =
        ConnectivityService().statusStream.listen(onStatusChanged);
  }

  /// Stop listening to connectivity changes
  void stopConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Get current connectivity status
  bool get isOnline => ConnectivityService().isOnline;

  /// Get current connectivity status
  bool get isOffline => ConnectivityService().isOffline;
}
