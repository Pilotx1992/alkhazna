import 'package:google_sign_in/google_sign_in.dart';
import 'google_sign_in_service.dart';

/// Service for handling Google Drive authentication with silent sign-in support
/// Now uses the unified GoogleSignInService to ensure consistency
class DriveAuthService {
  static final DriveAuthService _instance = DriveAuthService._internal();
  factory DriveAuthService() => _instance;
  DriveAuthService._internal();

  final GoogleSignInService _authService = GoogleSignInService();

  /// Attempt silent sign-in first, then fallback to interactive if needed
  Future<GoogleSignInAccount?> signInSilently() async {
    return await _authService.signInSilently();
  }

  /// Interactive sign-in (fallback when silent fails)
  Future<GoogleSignInAccount?> signInInteractive() async {
    return await _authService.signIn();
  }

  /// Get authentication headers for API calls
  /// Tries silent first, then interactive if interactiveFallback is true
  Future<Map<String, String>?> getAuthHeaders({
    bool interactiveFallback = true,
  }) async {
    return await _authService.getAuthHeaders(interactiveFallback: interactiveFallback);
  }

  /// Check if user is currently signed in
  bool get isSignedIn => _authService.isSignedIn;

  /// Get current user account
  GoogleSignInAccount? get currentUser => _authService.currentUser;

  /// Sign out from Google
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Disconnect (revoke access)
  Future<void> disconnect() async {
    await _authService.disconnect();
  }
}
