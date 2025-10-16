import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Unified singleton service for Google Sign-In
/// Ensures all services use the same GoogleSignIn instance and account
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  /// Single GoogleSignIn instance for the entire app
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
      'email',
      'profile',
    ],
  );

  /// Get the GoogleSignIn instance
  GoogleSignIn get instance => _googleSignIn;

  /// Get current signed-in account
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Attempt silent sign-in first
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      if (kDebugMode) {
        print('[GoogleSignInService] Attempting silent sign-in...');
      }
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        if (kDebugMode) {
          print('[GoogleSignInService] ✅ Silent sign-in successful: ${account.email} (${account.id})');
        }
      } else {
        if (kDebugMode) {
          print('[GoogleSignInService] ⚠️ Silent sign-in returned null');
        }
      }
      return account;
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Silent sign-in failed: $e');
      }
      return null;
    }
  }

  /// Interactive sign-in (shows UI)
  Future<GoogleSignInAccount?> signIn() async {
    try {
      if (kDebugMode) {
        print('[GoogleSignInService] Starting interactive sign-in...');
      }
      final account = await _googleSignIn.signIn();
      if (account != null) {
        if (kDebugMode) {
          print('[GoogleSignInService] ✅ Interactive sign-in successful: ${account.email} (${account.id})');
        }
      } else {
        if (kDebugMode) {
          print('[GoogleSignInService] ⚠️ User cancelled sign-in');
        }
      }
      return account;
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Interactive sign-in failed: $e');
      }
      return null;
    }
  }

  /// Get authentication headers for API calls
  Future<Map<String, String>?> getAuthHeaders({
    bool interactiveFallback = true,
  }) async {
    try {
      // Try to get current account first
      var account = currentUser;

      // If no current account, try silent sign-in
      if (account == null) {
        if (kDebugMode) {
          print('[GoogleSignInService] No current user, trying silent sign-in...');
        }
        account = await signInSilently();
      }

      // If still no account and fallback is enabled, try interactive
      if (account == null && interactiveFallback) {
        if (kDebugMode) {
          print('[GoogleSignInService] Silent sign-in failed, trying interactive...');
        }
        account = await signIn();
      }

      if (account == null) {
        if (kDebugMode) {
          print('[GoogleSignInService] ❌ No authenticated account available');
        }
        return null;
      }

      // Get auth headers
      final authHeaders = await account.authHeaders;
      if (kDebugMode) {
        print('[GoogleSignInService] ✅ Auth headers obtained for: ${account.email}');
        print('[GoogleSignInService]    Headers: ${authHeaders.keys.join(', ')}');
      }
      return authHeaders;
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Error getting auth headers: $e');
      }
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        print('[GoogleSignInService] Signing out...');
      }
      await _googleSignIn.signOut();
      if (kDebugMode) {
        print('[GoogleSignInService] ✅ Signed out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Error signing out: $e');
      }
    }
  }

  /// Disconnect (revoke access)
  Future<void> disconnect() async {
    try {
      if (kDebugMode) {
        print('[GoogleSignInService] Disconnecting...');
      }
      await _googleSignIn.disconnect();
      if (kDebugMode) {
        print('[GoogleSignInService] ✅ Disconnected successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Error disconnecting: $e');
      }
    }
  }

  /// Ensure we have a valid authenticated account
  /// Returns the account or null if authentication failed
  Future<GoogleSignInAccount?> ensureAuthenticated({
    bool interactiveFallback = true,
  }) async {
    // Try current user first
    var account = currentUser;
    if (account != null) {
      if (kDebugMode) {
        print('[GoogleSignInService] Using current account: ${account.email}');
      }
      return account;
    }

    // Try silent sign-in
    account = await signInSilently();
    if (account != null) {
      return account;
    }

    // Try interactive if enabled
    if (interactiveFallback) {
      account = await signIn();
      if (account != null) {
        return account;
      }
    }

    if (kDebugMode) {
      print('[GoogleSignInService] ❌ Failed to ensure authentication');
    }
    return null;
  }

  /// Validate that account has required information
  bool validateAccount(GoogleSignInAccount? account) {
    if (account == null) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Account is null');
      }
      return false;
    }

    if (account.email.isEmpty) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Account email is empty');
      }
      return false;
    }

    if (account.id.isEmpty) {
      if (kDebugMode) {
        print('[GoogleSignInService] ❌ Account ID is empty');
      }
      return false;
    }

    if (kDebugMode) {
      print('[GoogleSignInService] ✅ Account is valid: ${account.email} (${account.id})');
    }
    return true;
  }
}
