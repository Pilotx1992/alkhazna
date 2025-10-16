import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable PIN input widget with 4 dots and numeric keypad
/// Features: Shake animation, haptic feedback, auto-submit
class PinInputWidget extends StatefulWidget {
  /// Callback when 4 digits are entered
  final Function(String) onPinComplete;

  /// Optional callback on each digit change
  final Function(String)? onPinChanged;

  /// Error message to display (triggers shake animation)
  final String? errorMessage;

  /// Loading state (disables input)
  final bool isLoading;

  /// Title text above PIN dots
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Show biometric button below keypad
  final bool showBiometricButton;

  /// Callback for biometric button tap
  final VoidCallback? onBiometricTap;

  const PinInputWidget({
    super.key,
    required this.onPinComplete,
    this.onPinChanged,
    this.errorMessage,
    this.isLoading = false,
    this.title = 'Enter PIN',
    this.subtitle,
    this.showBiometricButton = false,
    this.onBiometricTap,
  });

  @override
  State<PinInputWidget> createState() => PinInputWidgetState();
}

class PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger shake animation when error message appears
    if (widget.errorMessage != null && oldWidget.errorMessage == null) {
      shake();
    }
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4 && !widget.isLoading) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += digit;
      });
      widget.onPinChanged?.call(_pin);

      if (_pin.length == 4) {
        // Auto-submit when 4 digits entered
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_pin.length == 4) {
            widget.onPinComplete(_pin);
          }
        });
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty && !widget.isLoading) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      widget.onPinChanged?.call(_pin);
    }
  }

  /// Clear the PIN input
  void clearPin() {
    setState(() {
      _pin = '';
    });
  }

  /// Trigger shake animation (for errors)
  void shake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  /// Trigger success haptic feedback
  void triggerSuccessHaptic() {
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
          textAlign: TextAlign.center,
        ),

        if (widget.subtitle != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // PIN Dots with shake animation
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              final hasError = widget.errorMessage != null;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (hasError ? Colors.red : Colors.indigo)
                      : Colors.grey[300],
                  border: Border.all(
                    color: hasError ? Colors.red : Colors.indigo,
                    width: 2,
                  ),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: (hasError ? Colors.red : Colors.indigo)
                                .withAlpha((0.3 * 255).round()),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isFilled
                    ? Center(
                        child: Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 12,
                        ),
                      )
                    : null,
              );
            }),
          ),
        ),

        // Error Message
        const SizedBox(height: 12),
        SizedBox(
          height: 20,
          child: widget.errorMessage != null
              ? Text(
                  widget.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              : null,
        ),

        const SizedBox(height: 24),

        // Numeric Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Row 1: 1 2 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: 4 5 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: 7 8 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 4: [biometric/empty] 0 [delete]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Show biometric button or empty space
              widget.showBiometricButton
                  ? _buildBiometricKeypadButton()
                  : const SizedBox(width: 70, height: 70),
              _buildKey('0'),
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    final isDisabled = widget.isLoading;

    return Material(
      color: isDisabled ? Colors.grey[300] : Colors.white,
      elevation: isDisabled ? 0 : 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: isDisabled ? null : () => _onKeyPress(digit),
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey[500] : Colors.indigo,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    final isDisabled = widget.isLoading || _pin.isEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : _onDelete,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: isDisabled ? Colors.grey[400] : Colors.indigo,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricKeypadButton() {
    final isDisabled = widget.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : widget.onBiometricTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Icon(
            Icons.fingerprint,
            size: 32,
            color: isDisabled ? Colors.grey[400] : Colors.indigo,
          ),
        ),
      ),
    );
  }
}
