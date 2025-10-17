import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/security_service.dart';
import '../../widgets/pin_input_widget.dart';

/// Setup PIN screen with 2-step confirmation
/// Step 1: Enter PIN
/// Step 2: Confirm PIN
/// Shows weak PIN warnings but allows proceed
class SetupPinScreen extends StatefulWidget {
  const SetupPinScreen({super.key});

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<PinInputWidgetState> _step1Key = GlobalKey();
  final GlobalKey<PinInputWidgetState> _step2Key = GlobalKey();

  String? _firstPin;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStep1Complete(String pin) async {
    final securityService = context.read<SecurityService>();

    // Check if PIN is weak
    final isWeak = securityService.isPinWeak(pin);
    if (isWeak) {
      // Show warning dialog
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Weak PIN'),
            ],
          ),
          content: Text(
            'This PIN is ${securityService.getPinStrengthDescription(pin).toLowerCase()}.\n\n'
            'We recommend using a stronger PIN for better security.\n\n'
            'Do you want to continue with this PIN?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Choose Different'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Continue Anyway'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        // Clear PIN and let user try again
        _step1Key.currentState?.clearPin();
        return;
      }
    }

    // Store first PIN and move to confirmation
    setState(() {
      _firstPin = pin;
      _errorMessage = null;
    });

    await _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onStep2Complete(String pin) async {
    if (_firstPin != pin) {
      // PINs don't match
      setState(() {
        _errorMessage = "PINs don't match. Try again.";
      });
      _step2Key.currentState?.shake();
      _step2Key.currentState?.clearPin();
      return;
    }

    // PINs match - setup PIN
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final securityService = context.read<SecurityService>();
      await securityService.setupPin(pin);

      // Success! Show success dialog
      if (mounted) {
        _step2Key.currentState?.triggerSuccessHaptic();

        final shouldEnableBiometric = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Text('Setup Complete'),
              ],
            ),
            content: const Text(
              'Your PIN has been set successfully!\n\n'
              'Would you like to enable fingerprint unlock for faster access?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Enable Fingerprint'),
              ),
            ],
          ),
        );

        if (shouldEnableBiometric == true && mounted) {
          // Try to enable biometric
          try {
            final securityService = context.read<SecurityService>();
            await securityService.enableBiometric();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fingerprint unlock enabled!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not enable fingerprint: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        // Navigate back to settings
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error setting up PIN: $e';
        _isLoading = false;
      });
      _step2Key.currentState?.shake();
      _step2Key.currentState?.clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Setup PIN'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe
          children: [
            // Step 1: Enter PIN
            _buildStep1(),
            // Step 2: Confirm PIN
            _buildStep2(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // PIN Input
          PinInputWidget(
            key: _step1Key,
            title: 'Create your PIN',
            subtitle: 'Enter a 4-digit PIN to protect your financial data',
            onPinComplete: _onStep1Complete,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 24),

          // Info text
          Text(
            'You can enable fingerprint unlock later',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressDot(true),
              Container(
                width: 40,
                height: 2,
                color: Colors.indigo,
              ),
              _buildProgressDot(true),
            ],
          ),

          const SizedBox(height: 16),

          // PIN Input
          PinInputWidget(
            key: _step2Key,
            title: 'Confirm your PIN',
            subtitle: 'Re-enter your PIN to confirm',
            onPinComplete: _onStep2Complete,
            errorMessage: _errorMessage,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 16),

          // Back button
          if (!_isLoading)
            TextButton.icon(
              onPressed: () async {
                setState(() {
                  _firstPin = null;
                  _errorMessage = null;
                });
                await _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _step1Key.currentState?.clearPin();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
