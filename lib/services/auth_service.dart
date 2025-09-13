import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:validators/validators.dart';

import '../models/auth_state.dart';
import '../models/user.dart';

/// Comprehensive authentication service
class AuthService extends ChangeNotifier {
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user_id';
  
  // Secure storage for sensitive data
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Google Sign-In configuration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
      'email',
      'profile',
    ],
  );

  // Local authentication
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Current authentication state
  AuthState _authState = AuthState.initial();
  AuthState get authState => _authState;

  // Hive boxes
  Box<User>? _usersBox;

  /// Initialize authentication service
  Future<void> initialize() async {
    try {
      debugPrint('🔄 Auth initialization starting...');
      _updateState(_authState.loading());
      
      // User adapter is already registered in main.dart with TypeId 4
      debugPrint('📦 Opening Hive box...');
      
      // Open boxes with timeout
      _usersBox = await Hive.openBox<User>(_usersBoxName).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('❌ Hive box timeout');
          throw Exception('Hive box timeout');
        },
      );
      
      debugPrint('✅ Hive box opened successfully');
      
      // Check biometric availability with timeout
      debugPrint('🔐 Checking biometric availability...');
      final bool biometricAvailable = await _checkBiometricAvailability();
      debugPrint('✅ Biometric check complete: $biometricAvailable');
      
      // Try to restore previous session
      debugPrint('🔄 Restoring session...');
      await _restoreSession(biometricAvailable);
      debugPrint('✅ Auth initialization complete');
      
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
      // If initialization fails, show login screen anyway
      debugPrint('🔄 Falling back to login screen');
      _updateState(_authState.unauthenticated().copyWith(biometricAvailable: false));
    }
  }

  /// Check if biometric authentication is available
  Future<bool> _checkBiometricAvailability() async {
    try {
      // Add timeout for emulator compatibility
      final Future<bool> availabilityCheck = Future.wait([
        _localAuth.canCheckBiometrics,
        _localAuth.isDeviceSupported(),
      ]).then((results) => results[0] && results[1]);
      
      final bool result = await availabilityCheck.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Biometric check timeout - assuming not available');
          return false;
        },
      );
      
      return result;
    } catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Restore previous authentication session
  Future<void> _restoreSession(bool biometricAvailable) async {
    try {
      debugPrint('🔍 Reading stored user ID...');
      final String? currentUserId = await _secureStorage.read(key: _currentUserKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('❌ Secure storage timeout');
          return null;
        },
      );
      
      debugPrint('📝 Current user ID: $currentUserId');
      
      if (currentUserId != null && _usersBox != null) {
        debugPrint('🔍 Looking up user in Hive...');
        final User? user = _usersBox!.get(currentUserId);
        if (user != null) {
          debugPrint('✅ User found: ${user.username}');
          // User exists, check if biometric is enabled and prompt
          if (user.biometricEnabled && biometricAvailable) {
            debugPrint('🔐 User has biometric enabled, setting state for biometric prompt...');
            _updateState(_authState.unauthenticated().copyWith(
              currentUser: user,
              biometricAvailable: biometricAvailable,
            ));
          } else {
            debugPrint('🔑 User doesn\'t require biometric, auto-authenticating...');
            // Auto-authenticate user without biometric
            user.updateLastLogin();
            _updateState(_authState.authenticated(user, AuthMethod.password));
          }
        } else {
          debugPrint('❌ User not found in Hive, clearing stored ID...');
          // User not found, clear stored ID and show login screen
          await _secureStorage.delete(key: _currentUserKey);
          _updateState(_authState.unauthenticated().copyWith(biometricAvailable: biometricAvailable));
        }
      } else {
        debugPrint('🆕 No current user - showing login screen');
        // No current user - show login screen
        _updateState(_authState.unauthenticated().copyWith(biometricAvailable: biometricAvailable));
      }
    } catch (e) {
      debugPrint('❌ Session restoration error: $e');
      // Always fall back to login screen on error
      _updateState(_authState.unauthenticated().copyWith(biometricAvailable: biometricAvailable));
    }
  }

  /// Sign up with username/email and password
  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    try {
      _updateState(_authState.loading());

      // Validate inputs
      final validation = _validateSignupInputs(username, email, password, confirmPassword);
      if (!validation.isValid) {
        _updateState(_authState.error(validation.error!));
        return false;
      }

      // Check if user already exists
      if (await _userExists(username, email)) {
        _updateState(_authState.error('User with this username or email already exists'));
        return false;
      }

      // Hash password
      final String passwordHash = _hashPassword(password);

      // Create user
      final User user = User.create(
        username: username.trim(),
        email: email.trim().toLowerCase(),
        passwordHash: passwordHash,
      );

      // Save user
      await _usersBox!.put(user.id, user);
      await _secureStorage.write(key: _currentUserKey, value: user.id);

      // Update state
      _updateState(_authState.authenticated(user, AuthMethod.password));
      return true;

    } catch (e) {
      debugPrint('Signup error: $e');
      _updateState(_authState.error('Failed to create account: ${e.toString()}'));
      return false;
    }
  }

  /// Sign in with username/email and password
  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      _updateState(_authState.loading());

      // Validate inputs
      if (usernameOrEmail.trim().isEmpty || password.isEmpty) {
        _updateState(_authState.error('Please enter username/email and password'));
        return false;
      }

      // Find user
      final User? user = await _findUser(usernameOrEmail.trim());
      if (user == null) {
        _updateState(_authState.error('Invalid username/email or password'));
        return false;
      }

      // Verify password
      if (!_verifyPassword(password, user.passwordHash)) {
        _updateState(_authState.error('Invalid username/email or password'));
        return false;
      }

      // Update last login
      user.updateLastLogin();
      await _secureStorage.write(key: _currentUserKey, value: user.id);

      // Update state
      _updateState(_authState.authenticated(user, AuthMethod.password));
      return true;

    } catch (e) {
      debugPrint('Signin error: $e');
      _updateState(_authState.error('Failed to sign in: $e'));
      return false;
    }
  }

  /// Sign in with biometric authentication
  Future<bool> signInWithBiometric() async {
    try {
      _updateState(_authState.loading());

      final User? user = _authState.currentUser;
      if (user == null || !user.biometricEnabled) {
        _updateState(_authState.error('Biometric authentication not set up'));
        return false;
      }

      // Check biometric availability
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _updateState(_authState.error('Biometric authentication not available'));
        return false;
      }

      // Authenticate with biometrics
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Al Khazna with your fingerprint or face',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        user.updateLastLogin();
        _updateState(_authState.authenticated(user, AuthMethod.biometric));
        return true;
      } else {
        _updateState(_authState.error('Biometric authentication failed'));
        return false;
      }

    } catch (e) {
      debugPrint('Biometric signin error: $e');
      _updateState(_authState.error('Biometric authentication error: ${e.toString()}'));
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _updateState(_authState.loading());

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        _updateState(_authState.error('Google sign-in cancelled'));
        return false;
      }

      // Check if user exists with this Google account
      User? user = await _findUserByGoogleAccount(account.id);
      
      if (user == null) {
        // Create new user with Google account
        user = User.create(
          username: account.displayName ?? account.email.split('@')[0],
          email: account.email,
          passwordHash: _generateRandomHash(), // Random hash for Google users
          googleAccountId: account.id,
          backupGoogleAccountEmail: account.email,
        );
        
        await _usersBox!.put(user.id, user);
      } else {
        // Update existing user's Google account info
        user.linkGoogleAccount(account.id, account.email);
      }

      await _secureStorage.write(key: _currentUserKey, value: user.id);
      _updateState(_authState.authenticated(user, AuthMethod.google));
      return true;

    } catch (e) {
      debugPrint('Google signin error: $e');
      _updateState(_authState.error('Google sign-in failed: ${e.toString()}'));
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      final User? user = _authState.currentUser;
      if (user == null) {
        return false;
      }

      // Check availability
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _updateState(_authState.error('Biometric authentication not available'));
        return false;
      }

      // Test biometric authentication
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric authentication for Al Khazna',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        user.setBiometricEnabled(true);
        _updateState(_authState.copyWith(currentUser: user));
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Enable biometric error: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    final User? user = _authState.currentUser;
    if (user != null) {
      user.setBiometricEnabled(false);
      _updateState(_authState.copyWith(currentUser: user));
    }
  }

  /// Link Google account for backup
  Future<bool> linkGoogleAccountForBackup() async {
    try {
      final User? user = _authState.currentUser;
      if (user == null) return false;

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      user.linkGoogleAccount(account.id, account.email);
      _updateState(_authState.copyWith(currentUser: user));
      return true;

    } catch (e) {
      debugPrint('Link Google account error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: _currentUserKey);
      await _googleSignIn.signOut();
      _updateState(AuthState.initial().copyWith(biometricAvailable: _authState.biometricAvailable));
    } catch (e) {
      debugPrint('Signout error: $e');
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    final User? user = _authState.currentUser;
    if (user != null) {
      user.completeOnboarding();
      _updateState(_authState.copyWith(currentUser: user));
    }
  }

  // Helper methods

  /// Validate signup inputs
  ({bool isValid, String? error}) _validateSignupInputs(
    String username, 
    String email, 
    String password, 
    String? confirmPassword,
  ) {
    if (username.trim().isEmpty) {
      return (isValid: false, error: 'Username is required');
    }
    
    if (username.trim().length < 3) {
      return (isValid: false, error: 'Username must be at least 3 characters');
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      return (isValid: false, error: 'Username can only contain letters, numbers, and underscores');
    }

    if (!isEmail(email.trim())) {
      return (isValid: false, error: 'Please enter a valid email address');
    }

    if (password.length < 8) {
      return (isValid: false, error: 'Password must be at least 8 characters');
    }

    if (confirmPassword != null && password != confirmPassword) {
      return (isValid: false, error: 'Passwords do not match');
    }

    return (isValid: true, error: null);
  }

  /// Hash password using bcrypt-style approach
  String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'alkhazna_salt_2024'); // Add salt
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  /// Generate random hash for Google users
  String _generateRandomHash() {
    final bytes = utf8.encode(DateTime.now().millisecondsSinceEpoch.toString());
    return sha256.convert(bytes).toString();
  }

  /// Check if user exists
  Future<bool> _userExists(String username, String email) async {
    if (_usersBox == null) return false;
    
    for (final user in _usersBox!.values) {
      if (user.username.toLowerCase() == username.toLowerCase() ||
          user.email.toLowerCase() == email.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  /// Find user by username or email
  Future<User?> _findUser(String usernameOrEmail) async {
    if (_usersBox == null) return null;
    
    final String searchTerm = usernameOrEmail.toLowerCase();
    for (final user in _usersBox!.values) {
      if (user.username.toLowerCase() == searchTerm ||
          user.email.toLowerCase() == searchTerm) {
        return user;
      }
    }
    return null;
  }

  /// Find user by Google account ID
  Future<User?> _findUserByGoogleAccount(String googleId) async {
    if (_usersBox == null) return null;
    
    for (final user in _usersBox!.values) {
      if (user.googleAccountId == googleId) {
        return user;
      }
    }
    return null;
  }

  /// Update authentication state
  void _updateState(AuthState newState) {
    _authState = newState;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _usersBox?.close();
    super.dispose();
  }
}