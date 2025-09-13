import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:validators/validators.dart';

import '../models/auth_state.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Modern signup screen with progressive user setup
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> 
    with TickerProviderStateMixin {
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // UI state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  
  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.red;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _passwordController.addListener(_updatePasswordStrength);
  }
  
  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.fastLinearToSlowEaseIn,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }
  
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
      _passwordStrengthText = _getPasswordStrengthText(_passwordStrength);
      _passwordStrengthColor = _getPasswordStrengthColor(_passwordStrength);
    });
  }
  
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    
    // Length check
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.1;
    
    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
    
    return strength.clamp(0.0, 1.0);
  }
  
  String _getPasswordStrengthText(double strength) {
    if (strength == 0) return '';
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }
  
  Color _getPasswordStrengthColor(double strength) {
    if (strength == 0) return Colors.transparent;
    if (strength < 0.3) return const Color(0xFFF44336);
    if (strength < 0.6) return const Color(0xFFFF9800);
    if (strength < 0.8) return const Color(0xFF2196F3);
    return const Color(0xFF4CAF50);
  }
  
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      _showErrorSnackBar('Please accept the terms and conditions');
      return;
    }
    
    HapticFeedback.lightImpact();
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final success = await authService.signUp(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _showAccountSetupFlow();
    }
  }
  
  Future<void> _handleGoogleSignUp() async {
    HapticFeedback.lightImpact();
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final success = await authService.signInWithGoogle();
    if (success && mounted) {
      HapticFeedback.mediumImpact();
      _showAccountSetupFlow();
    }
  }
  
  void _showAccountSetupFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _AccountSetupFlow(
        onComplete: _navigateToHome,
      ),
    );
  }
  
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final authState = authService.authState;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 32),
              
              // Signup form
              _buildSignupForm(authState),
              
              const SizedBox(height: 24),
              
              // Action buttons
              _buildActionButtons(authState),
              
              const SizedBox(height: 32),
              
              // Footer links
              _buildFooterLinks(),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 8),
       
      ],
    );
  }
  
  Widget _buildSignupForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username field
          _buildInputField(
            controller: _usernameController,
            label: 'Username',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Username is required';
              }
              if (value!.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                return 'Username can only contain letters, numbers, and underscores';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email field
          _buildInputField(
            controller: _emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'Email is required';
              }
              if (!isEmail(value!.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Password field with strength indicator
          Column(
            children: [
              _buildInputField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onTogglePasswordVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Password is required';
                  }
                  if (value!.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              
              // Password strength indicator
              if (_passwordController.text.isNotEmpty)
                _buildPasswordStrengthIndicator(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Confirm password field
          _buildInputField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            isPasswordVisible: _isConfirmPasswordVisible,
            onTogglePasswordVisibility: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Terms and conditions
          _buildTermsCheckbox(),
          
          // Error message
          if (authState.errorMessage != null)
            _buildErrorMessage(authState.errorMessage!),
        ],
      ),
    );
  }
  
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
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
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF757575),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onPressed: onTogglePasswordVisibility,
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
  
  Widget _buildPasswordStrengthIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            minHeight: 4,
          ),
          
          const SizedBox(height: 4),
          
          // Strength text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _passwordStrengthText,
                style: TextStyle(
                  fontSize: 12,
                  color: _passwordStrengthColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(_passwordStrength * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _passwordStrengthColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF2E7D32),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptTerms = !_acceptTerms;
              });
            },
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(AuthState authState) {
    return Column(
      children: [
        // Sign up button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Divider with "or"
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: const Color(0xFF757575).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Google sign up button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: authState.isLoading ? null : _handleGoogleSignUp,
            icon: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icon/google_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Icon(
                Icons.login,
                size: 18,
                color: Colors.transparent,
              ),
            ),
            label: const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Sign In',
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
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

/// Account setup flow after successful signup
class _AccountSetupFlow extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _AccountSetupFlow({
    required this.onComplete,
  });
  
  @override
  State<_AccountSetupFlow> createState() => _AccountSetupFlowState();
}

class _AccountSetupFlowState extends State<_AccountSetupFlow> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  final List<String> _steps = [
    'Google Account Binding',
    'Biometric Setup',
    'Welcome',
  ];
  
  Future<void> _handleGoogleBinding() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.linkGoogleAccountForBackup();
    
    setState(() {
      _isLoading = false;
    });
    
    if (success) {
      _nextStep();
    }
  }
  
  void _skipGoogleBinding() {
    _nextStep();
  }
  
  Future<void> _handleBiometricSetup() async {
    setState(() {
      _isLoading = true;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.enableBiometric();
    
    setState(() {
      _isLoading = false;
    });
    
    _nextStep();
  }
  
  void _skipBiometricSetup() {
    _nextStep();
  }
  
  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeSetup();
    }
  }
  
  Future<void> _completeSetup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.completeOnboarding();
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress indicator
          _buildProgressIndicator(),
          
          const SizedBox(height: 32),
          
          // Step content
          Expanded(
            child: _buildStepContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps.length, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _steps.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF2E7D32) 
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${_currentStep + 1} of ${_steps.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildGoogleBindingStep();
      case 1:
        return _buildBiometricSetupStep();
      case 2:
        return _buildWelcomeStep();
      default:
        return Container();
    }
  }
  
  Widget _buildGoogleBindingStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_sync,
            size: 64,
            color: Color(0xFF2E7D32),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Secure Backup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Link your Google account to enable secure backup of your financial data to Google Drive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.5,
            ),
          ),
          
          const Spacer(),
          
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleBinding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Link Google Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: _skipGoogleBinding,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBiometricSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(
            Icons.fingerprint,
            size: 64,
            color: Color(0xFF2E7D32),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Quick & Secure Access',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'Enable biometric authentication to quickly and securely access your account using your fingerprint or face.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.5,
            ),
          ),
          
          const Spacer(),
          
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleBiometricSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Enable Biometric Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: _skipBiometricSetup,
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF1565C0),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Welcome to Al Khazna!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Your secure personal finance tracker is ready to help you manage your income and expenses with confidence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.5,
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _completeSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}