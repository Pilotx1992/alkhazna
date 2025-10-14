import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for checking network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final isConnected = connectivityResult.contains(ConnectivityResult.mobile) || 
                         connectivityResult.contains(ConnectivityResult.wifi) ||
                         connectivityResult.contains(ConnectivityResult.ethernet);
      
      if (kDebugMode) {
        print('🌐 Connectivity check: ${connectivityResult.join(', ')} -> ${isConnected ? 'Online' : 'Offline'}');
      }
      
      return isConnected;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// Check if device is connected to WiFi
  Future<bool> isWifiConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.wifi);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking WiFi connectivity: $e');
      }
      return false;
    }
  }

  /// Check if device is connected to mobile data
  Future<bool> isMobileConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking mobile connectivity: $e');
      }
      return false;
    }
  }

  /// Get current connectivity status as string
  Future<String> getConnectivityStatus() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        return 'WiFi';
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return 'Mobile Data';
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return 'Ethernet';
      } else {
        return 'No Connection';
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting connectivity status: $e');
      }
      return 'Unknown';
    }
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  /// Listen to connectivity changes
  void listenToConnectivityChanges(Function(List<ConnectivityResult>) onConnectivityChanged) {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      if (kDebugMode) {
        print('🔄 Connectivity changed: ${result.join(', ')}');
      }
      onConnectivityChanged(result);
    });
  }
}
