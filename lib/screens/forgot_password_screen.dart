import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/email_service.dart';

/// Forgot password screen for resetting user password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // UI state
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Verification flow state
  int _currentStep = 1; // 1: Email, 2: Code, 3: New Password

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    ));

    _fadeController.forward();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    final authService = Provider.of<AuthService>(context, listen: false);
    final emailService = EmailService();

    // Check if user exists first
    final userExists = await authService.checkUserExists(_emailController.text.trim());

    if (!userExists) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No account found with this email';
      });
      return;
    }

    // Send verification code
    final codeSent = await emailService.sendVerificationCode(_emailController.text.trim());

    setState(() {
      _isLoading = false;
      if (codeSent) {
        _currentStep = 2;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to send verification code. Please try again.';
      }
    });

    if (codeSent) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    final emailService = EmailService();

    // Verify the code
    final codeValid = emailService.verifyCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (codeValid) {
        _currentStep = 3;
        _errorMessage = null;
      } else {
        _errorMessage = 'Invalid or expired verification code';
      }
    });

    if (codeValid) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();
    final authService = Provider.of<AuthService>(context, listen: false);

    // Reset password
    final success = await authService.resetPassword(
      usernameOrEmail: _emailController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _showSuccessDialog();
    } else {
      setState(() {
        _errorMessage = 'Failed to reset password. Please try again.';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: Color(0xFF2E7D32),
            ),
          ),
          title: const Text(
            'Password Reset Successfully',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          content: const Text(
            'Your password has been updated successfully. You can now sign in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // Header icon
          _buildHeaderIcon(),

          const SizedBox(height: 32),

          // Title and description
          _buildHeader(),

          const SizedBox(height: 40),

          // Form
          _buildForm(),

          const SizedBox(height: 32),

          // Action button
          _buildActionButton(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getStepIcon(),
          size: 40,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          _getStepTitle(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _getStepDescription(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF757575),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Step 1: Email field
          if (_currentStep == 1) ...[
            _buildInputField(
              controller: _emailController,
              label: 'Email Address',
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter your email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ],

          // Step 2: Verification code field
          if (_currentStep == 2) ...[
            _buildInputField(
              controller: _codeController,
              label: 'Verification Code',
              prefixIcon: Icons.security,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Please enter the verification code';
                }
                if (value!.length != 6) {
                  return 'Verification code must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildResendCodeButton(),
          ],

          // Step 3: New password fields
          if (_currentStep == 3) ...[
            _buildInputField(
              controller: _newPasswordController,
              label: 'New Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isNewPassword: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a new password';
                }
                if (value!.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildInputField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              isConfirmPassword: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please confirm your new password';
                }
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],

          // Error message
          if (_errorMessage != null)
            _buildErrorMessage(_errorMessage!),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isNewPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
  }) {
    bool isVisible = false;
    if (isNewPassword) {
      isVisible = _isNewPasswordVisible;
    } else if (isConfirmPassword) {
      isVisible = _isConfirmPasswordVisible;
    }

    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF212121),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF757575),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF757575),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: () {
                  setState(() {
                    if (isNewPassword) {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    } else if (isConfirmPassword) {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    }
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE0E0E0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2E7D32),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFF44336),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _getCurrentStepAction(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _getCurrentStepButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFF44336),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for step-based UI
  IconData _getStepIcon() {
    switch (_currentStep) {
      case 1:
        return Icons.email_outlined;
      case 2:
        return Icons.security;
      case 3:
        return Icons.lock_reset;
      default:
        return Icons.help_outline;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Find Your Account';
      case 2:
        return 'Verify Your Email';
      case 3:
        return 'Create New Password';
      default:
        return 'Reset Password';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Enter your email address to receive a verification code';
      case 2:
        return 'Enter the 6-digit code we sent to ${_emailController.text}';
      case 3:
        return 'Create a new password for your account';
      default:
        return 'Reset your password';
    }
  }

  VoidCallback _getCurrentStepAction() {
    switch (_currentStep) {
      case 1:
        return _handleSendCode;
      case 2:
        return _handleVerifyCode;
      case 3:
        return _handleResetPassword;
      default:
        return _handleSendCode;
    }
  }

  String _getCurrentStepButtonText() {
    switch (_currentStep) {
      case 1:
        return 'Send Code';
      case 2:
        return 'Verify Code';
      case 3:
        return 'Reset Password';
      default:
        return 'Continue';
    }
  }

  Widget _buildResendCodeButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Didn't receive the code?",
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () {
            _handleSendCode();
          },
          child: const Text(
            'Resend',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}