import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/security_service.dart';
import '../../widgets/pin_input_widget.dart';

/// Change PIN screen with 3-step flow
/// Step 1: Verify current PIN
/// Step 2: Enter new PIN
/// Step 3: Confirm new PIN
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<PinInputWidgetState> _step1Key = GlobalKey();
  final GlobalKey<PinInputWidgetState> _step2Key = GlobalKey();
  final GlobalKey<PinInputWidgetState> _step3Key = GlobalKey();

  String? _currentPin;
  String? _newPin;
  String? _errorMessage;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStep1Complete(String pin) async {
    final securityService = context.read<SecurityService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify current PIN
      final isCorrect = await securityService.verifyPin(pin);

      if (isCorrect) {
        // Store current PIN and move to next step
        setState(() {
          _currentPin = pin;
          _isLoading = false;
          _currentStep = 1;
        });

        await _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        setState(() {
          _errorMessage = 'Incorrect current PIN';
          _isLoading = false;
        });
        _step1Key.currentState?.shake();
        _step1Key.currentState?.clearPin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _step1Key.currentState?.shake();
      _step1Key.currentState?.clearPin();
    }
  }

  void _onStep2Complete(String pin) async {
    final securityService = context.read<SecurityService>();

    // Check if new PIN is same as current
    if (pin == _currentPin) {
      setState(() {
        _errorMessage = 'New PIN must be different';
      });
      _step2Key.currentState?.shake();
      _step2Key.currentState?.clearPin();
      return;
    }

    // Check if PIN is weak
    final isWeak = securityService.isPinWeak(pin);
    if (isWeak && mounted) {
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
        _step2Key.currentState?.clearPin();
        return;
      }
    }

    // Store new PIN and move to confirmation
    setState(() {
      _newPin = pin;
      _errorMessage = null;
      _currentStep = 2;
    });

    await _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onStep3Complete(String pin) async {
    if (_newPin != pin) {
      setState(() {
        _errorMessage = "PINs don't match";
      });
      _step3Key.currentState?.shake();
      _step3Key.currentState?.clearPin();
      return;
    }

    // Change PIN
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final securityService = context.read<SecurityService>();
      await securityService.changePin(_currentPin!, _newPin!);

      // Success!
      _step3Key.currentState?.triggerSuccessHaptic();

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                const Text('Success'),
              ],
            ),
            content: const Text('Your PIN has been changed successfully!'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Navigate back to settings
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _step3Key.currentState?.shake();
      _step3Key.currentState?.clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Change PIN'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildProgressDot(0),
                  _buildProgressLine(0),
                  _buildProgressDot(1),
                  _buildProgressLine(1),
                  _buildProgressDot(2),
                ],
              ),
            ),

            // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          PinInputWidget(
            key: _step1Key,
            title: 'Enter Current PIN',
            subtitle: 'Verify your current PIN to continue',
            onPinComplete: _onStep1Complete,
            errorMessage: _errorMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          PinInputWidget(
            key: _step2Key,
            title: 'Enter New PIN',
            subtitle: 'Choose a new 4-digit PIN',
            onPinComplete: _onStep2Complete,
            errorMessage: _errorMessage,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          if (!_isLoading)
            TextButton.icon(
              onPressed: () async {
                setState(() {
                  _currentStep = 0;
                  _errorMessage = null;
                });
                await _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          PinInputWidget(
            key: _step3Key,
            title: 'Confirm New PIN',
            subtitle: 'Re-enter your new PIN',
            onPinComplete: _onStep3Complete,
            errorMessage: _errorMessage,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          if (!_isLoading)
            TextButton.icon(
              onPressed: () async {
                setState(() {
                  _currentStep = 1;
                  _errorMessage = null;
                });
                await _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                _step2Key.currentState?.clearPin();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int step) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = step < _currentStep;

    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.indigo : Colors.grey[300],
    );
  }
}
