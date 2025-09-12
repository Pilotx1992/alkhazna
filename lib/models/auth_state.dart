import 'package:google_sign_in/google_sign_in.dart';
import 'user.dart';

/// Authentication methods available
enum AuthMethod {
  none,
  password,
  biometric,
  google,
}

/// Current authentication state
class AuthState {
  final bool isAuthenticated;
  final User? currentUser;
  final AuthMethod lastAuthMethod;
  final bool biometricAvailable;
  final List<GoogleSignInAccount> availableGoogleAccounts;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.currentUser,
    this.lastAuthMethod = AuthMethod.none,
    this.biometricAvailable = false,
    this.availableGoogleAccounts = const [],
    this.errorMessage,
    this.isLoading = false,
  });

  /// Create initial/empty state
  factory AuthState.initial() {
    return const AuthState();
  }

  /// Create loading state
  AuthState loading() {
    return copyWith(isLoading: true, errorMessage: null);
  }

  /// Create authenticated state
  AuthState authenticated(User user, AuthMethod method) {
    return copyWith(
      isAuthenticated: true,
      currentUser: user,
      lastAuthMethod: method,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Create unauthenticated state
  AuthState unauthenticated([String? error]) {
    return copyWith(
      isAuthenticated: false,
      currentUser: null,
      lastAuthMethod: AuthMethod.none,
      isLoading: false,
      errorMessage: error,
    );
  }

  /// Create error state
  AuthState error(String message) {
    return copyWith(
      isLoading: false,
      errorMessage: message,
    );
  }

  /// Copy with new values
  AuthState copyWith({
    bool? isAuthenticated,
    User? currentUser,
    AuthMethod? lastAuthMethod,
    bool? biometricAvailable,
    List<GoogleSignInAccount>? availableGoogleAccounts,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      lastAuthMethod: lastAuthMethod ?? this.lastAuthMethod,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      availableGoogleAccounts: availableGoogleAccounts ?? this.availableGoogleAccounts,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Check if user should see biometric prompt
  bool get shouldShowBiometric => 
    currentUser?.biometricEnabled == true && 
    biometricAvailable && 
    lastAuthMethod != AuthMethod.biometric;

  /// Check if user needs to complete onboarding
  bool get needsOnboarding => currentUser?.isFirstTime == true;

  /// Check if user has Google account linked
  bool get hasGoogleAccountLinked => currentUser?.hasLinkedGoogleAccount == true;

  @override
  String toString() {
    return 'AuthState{authenticated: $isAuthenticated, user: ${currentUser?.username}, method: $lastAuthMethod, loading: $isLoading, error: $errorMessage}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthState &&
      other.isAuthenticated == isAuthenticated &&
      other.currentUser?.id == currentUser?.id &&
      other.lastAuthMethod == lastAuthMethod &&
      other.biometricAvailable == biometricAvailable &&
      other.errorMessage == errorMessage &&
      other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      isAuthenticated,
      currentUser?.id,
      lastAuthMethod,
      biometricAvailable,
      errorMessage,
      isLoading,
    );
  }
}