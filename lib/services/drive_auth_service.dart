import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Google Drive authentication with silent sign-in support
class DriveAuthService {
  static final DriveAuthService _instance = DriveAuthService._internal();
  factory DriveAuthService() => _instance;
  DriveAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  /// Attempt silent sign-in first, then fallback to interactive if needed
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      if (kDebugMode) {
        print('🔐 Attempting silent sign-in...');
      }
      final account = await _googleSignIn.signInSilently();
      if (account != null && kDebugMode) {
        print('✅ Silent sign-in successful: ${account.email}');
      }
      return account;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Silent sign-in failed: $e');
      }
      return null;
    }
  }

  /// Interactive sign-in (fallback when silent fails)
  Future<GoogleSignInAccount?> signInInteractive() async {
    try {
      if (kDebugMode) {
        print('🔐 Starting interactive sign-in...');
      }
      final account = await _googleSignIn.signIn();
      if (account != null && kDebugMode) {
        print('✅ Interactive sign-in successful: ${account.email}');
      }
      return account;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Interactive sign-in failed: $e');
      }
      return null;
    }
  }

  /// Get authentication headers for API calls
  /// Tries silent first, then interactive if interactiveFallback is true
  Future<Map<String, String>?> getAuthHeaders({
    bool interactiveFallback = true,
  }) async {
    try {
      // Try silent sign-in first
      var account = await signInSilently();
      
      // If silent failed and fallback is enabled, try interactive
      if (account == null && interactiveFallback) {
        if (kDebugMode) {
          print('🔄 Silent sign-in failed, trying interactive...');
        }
        account = await signInInteractive();
      }

      if (account == null) {
        if (kDebugMode) {
          print('❌ No authenticated account available');
        }
        return null;
      }

      // Get auth headers
      final authHeaders = await account.authHeaders;
      if (kDebugMode) {
        print('✅ Auth headers obtained for: ${account.email}');
      }
      return authHeaders;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting auth headers: $e');
      }
      return null;
    }
  }

  /// Check if user is currently signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Get current user account
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (kDebugMode) {
        print('✅ Signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error signing out: $e');
      }
    }
  }

  /// Disconnect (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      if (kDebugMode) {
        print('✅ Disconnected successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting: $e');
      }
    }
  }
}
