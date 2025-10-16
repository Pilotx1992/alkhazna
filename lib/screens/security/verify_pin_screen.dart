import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/security_service.dart';
import '../../widgets/pin_input_widget.dart';

/// Verify PIN screen for sensitive operations
/// Used before: changing PIN, deleting data, exporting, etc.
/// No lockout mechanism (different from UnlockScreen)
class VerifyPinScreen extends StatefulWidget {
  final String title;
  final String? subtitle;

  const VerifyPinScreen({
    super.key,
    this.title = 'Verify your PIN',
    this.subtitle,
  });

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  final GlobalKey<PinInputWidgetState> _pinKey = GlobalKey();
  String? _errorMessage;
  bool _isLoading = false;

  void _onPinComplete(String pin) async {
    final securityService = context.read<SecurityService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isCorrect = await securityService.verifyPin(pin);

      if (isCorrect) {
        // Success! Return true
        _pinKey.currentState?.triggerSuccessHaptic();
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Wrong PIN - allow retry
        setState(() {
          _errorMessage = 'Incorrect PIN. Try again';
          _isLoading = false;
        });
        _pinKey.currentState?.shake();
        _pinKey.currentState?.clearPin();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _pinKey.currentState?.shake();
      _pinKey.currentState?.clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Verify PIN'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Lock Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 60),

              // PIN Input
              PinInputWidget(
                key: _pinKey,
                title: widget.title,
                subtitle: widget.subtitle ?? 'Enter your PIN to continue',
                onPinComplete: _onPinComplete,
                errorMessage: _errorMessage,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              // Info text
              Text(
                'This action requires PIN verification',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
