import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for checking network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connection (with real internet check)
  Future<bool> isOnline() async {
    try {
      // Step 1: Check if device has network interface
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetworkInterface = connectivityResult.contains(ConnectivityResult.mobile) || 
                                   connectivityResult.contains(ConnectivityResult.wifi) ||
                                   connectivityResult.contains(ConnectivityResult.ethernet);
      
      if (!hasNetworkInterface) {
        if (kDebugMode) {
          print('🌐 No network interface available');
        }
        return false;
      }

      // Step 2: Check real internet connectivity with timeout
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 5));
        
        final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        
        if (kDebugMode) {
          print('🌐 Real internet check: ${isOnline ? 'Online' : 'Offline'}');
        }
        
        return isOnline;
      } catch (e) {
        if (kDebugMode) {
          print('🌐 Internet check failed: $e');
        }
        return false;
      }
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
