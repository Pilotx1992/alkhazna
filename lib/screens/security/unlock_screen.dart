import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/security_service.dart';
import '../../widgets/pin_input_widget.dart';

/// Unlock screen shown when app is locked
/// Features: PIN input, biometric unlock, lockout countdown
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final GlobalKey<PinInputWidgetState> _pinKey = GlobalKey();
  String? _errorMessage;
  bool _isLoading = false;
  Timer? _lockoutTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometricAutoPrompt();
    _startLockoutTimer();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// Auto-prompt biometric on screen load
  void _checkBiometricAutoPrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      final securityService = context.read<SecurityService>();
      if (securityService.isBiometricEnabled && !securityService.isLockedOut) {
        _onBiometricTap();
      }
    }
  }

  /// Start timer for lockout countdown
  void _startLockoutTimer() {
    final securityService = context.read<SecurityService>();
    if (securityService.isLockedOut) {
      setState(() {
        _remainingSeconds = securityService.lockoutRemainingSeconds;
      });

      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final securityService = context.read<SecurityService>();
        final remaining = securityService.lockoutRemainingSeconds;

        setState(() {
          _remainingSeconds = remaining;
        });

        if (remaining <= 0) {
          timer.cancel();
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _onPinComplete(String pin) async {
    final securityService = context.read<SecurityService>();

    // Check if locked out
    if (securityService.isLockedOut) {
      setState(() {
        _errorMessage = 'Locked out. Wait $_remainingSeconds seconds';
      });
      _pinKey.currentState?.shake();
      _pinKey.currentState?.clearPin();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isCorrect = await securityService.verifyPin(pin);

      if (isCorrect) {
        // Success! Trigger success feedback
        _pinKey.currentState?.triggerSuccessHaptic();

        // Small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 200));

        // App is now unlocked, SecurityWrapper will handle navigation
      } else {
        // Wrong PIN
        final attemptsLeft = 5 - securityService.failedAttempts;
        setState(() {
          _errorMessage = attemptsLeft > 0
              ? 'Incorrect PIN. $attemptsLeft attempts left'
              : 'Too many attempts';
          _isLoading = false;
        });
        _pinKey.currentState?.shake();
        _pinKey.currentState?.clearPin();

        // Restart timer if lockout was triggered
        if (securityService.isLockedOut) {
          _startLockoutTimer();
        }
      }
    } on LockoutException catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _pinKey.currentState?.shake();
      _pinKey.currentState?.clearPin();
      _startLockoutTimer();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _pinKey.currentState?.shake();
      _pinKey.currentState?.clearPin();
    }
  }

  void _onBiometricTap() async {
    final securityService = context.read<SecurityService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await securityService.authenticateWithBiometric();

      if (success) {
        // Success! App is now unlocked
        _pinKey.currentState?.triggerSuccessHaptic();
      } else {
        // Biometric failed, allow PIN entry
        setState(() {
          _isLoading = false;
          _errorMessage = 'Biometric failed. Use PIN instead';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Biometric error. Use PIN instead';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final securityService = context.watch<SecurityService>();
    final isLockedOut = securityService.isLockedOut;

    return PopScope(
      canPop: false, // Prevent back navigation when locked
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: Colors.indigo,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Al Khazna',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                ),

                const SizedBox(height: 60),

                // Lockout message
                if (isLockedOut) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.red, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          'Too Many Failed Attempts',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait $_remainingSeconds seconds',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // PIN Input
                PinInputWidget(
                  key: _pinKey,
                  title: isLockedOut ? 'Locked' : 'Enter your PIN',
                  subtitle: isLockedOut
                      ? 'Wait for lockout to end'
                      : 'Unlock to access your data',
                  onPinComplete: _onPinComplete,
                  errorMessage: _errorMessage,
                  isLoading: _isLoading || isLockedOut,
                  showBiometricButton: securityService.isBiometricEnabled && !isLockedOut,
                  onBiometricTap: _onBiometricTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
