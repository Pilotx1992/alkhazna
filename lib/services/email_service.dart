import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

/// Service for sending email verification codes
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // For demo purposes - in production, use proper email server configuration
  static const String _senderEmail = 'alkhazna.app@gmail.com';
  static const String _senderPassword = 'your_app_password'; // Use app password for Gmail

  // Store verification codes temporarily (in production, use secure storage/database)
  final Map<String, _VerificationData> _verificationCodes = {};

  /// Generate a 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send verification code to email
  Future<bool> sendVerificationCode(String email) async {
    try {
      final code = _generateVerificationCode();

      // Store verification code with expiration (10 minutes)
      _verificationCodes[email.toLowerCase()] = _VerificationData(
        code: code,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      if (kDebugMode) {
        // In debug mode, just print the code for testing
        print('🔐 Verification code for $email: $code');
        return true;
      }

      // Configure SMTP server (Gmail example)
      final smtpServer = gmail(_senderEmail, _senderPassword);

      // Create message
      final message = Message()
        ..from = Address(_senderEmail, 'Al Khazna')
        ..recipients.add(email)
        ..subject = 'Password Reset Verification Code - Al Khazna'
        ..html = _buildEmailTemplate(code);

      // Send email
      await send(message, smtpServer);

      if (kDebugMode) {
        print('✅ Verification code sent to $email');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to send verification code: $e');
      }
      return false;
    }
  }

  /// Verify the code entered by user
  bool verifyCode(String email, String enteredCode) {
    final emailKey = email.toLowerCase();
    final verificationData = _verificationCodes[emailKey];

    if (verificationData == null) {
      if (kDebugMode) {
        print('❌ No verification code found for $email');
      }
      return false;
    }

    // Check if code has expired
    if (DateTime.now().isAfter(verificationData.expiresAt)) {
      _verificationCodes.remove(emailKey);
      if (kDebugMode) {
        print('❌ Verification code expired for $email');
      }
      return false;
    }

    // Check if code matches
    if (verificationData.code == enteredCode) {
      // Code is valid, remove it after use
      _verificationCodes.remove(emailKey);
      if (kDebugMode) {
        print('✅ Verification code verified for $email');
      }
      return true;
    }

    if (kDebugMode) {
      print('❌ Invalid verification code for $email');
    }
    return false;
  }

  /// Clear expired codes (cleanup method)
  void clearExpiredCodes() {
    final now = DateTime.now();
    _verificationCodes.removeWhere((key, data) => now.isAfter(data.expiresAt));
  }

  /// Build HTML email template
  String _buildEmailTemplate(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Password Reset - Al Khazna</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #2E7D32, #1565C0); padding: 30px; border-radius: 12px; text-align: center; margin-bottom: 30px;">
            <h1 style="color: white; margin: 0; font-size: 28px;">Al Khazna</h1>
            <p style="color: rgba(255, 255, 255, 0.9); margin: 5px 0 0 0; font-size: 16px;">Password Reset Request</p>
        </div>

        <div style="background: #f8f9fa; padding: 30px; border-radius: 12px; margin-bottom: 30px;">
            <h2 style="color: #2E7D32; margin-bottom: 20px;">Reset Your Password</h2>
            <p style="font-size: 16px; margin-bottom: 20px;">You requested to reset your password for your Al Khazna account. Use the verification code below to continue:</p>

            <div style="background: white; border: 2px dashed #2E7D32; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
                <p style="font-size: 14px; color: #757575; margin-bottom: 10px;">Your Verification Code:</p>
                <h1 style="font-size: 36px; color: #2E7D32; letter-spacing: 8px; margin: 0; font-family: 'Courier New', monospace;">$code</h1>
            </div>

            <p style="font-size: 14px; color: #757575; margin-bottom: 0;">This code will expire in <strong>10 minutes</strong> for your security.</p>
        </div>

        <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 20px; border-radius: 8px; margin-bottom: 30px;">
            <p style="margin: 0; font-size: 14px; color: #856404;">
                <strong>Security Notice:</strong> If you didn't request this password reset, please ignore this email. Your account is safe and no changes will be made.
            </p>
        </div>

        <div style="text-align: center; color: #757575; font-size: 12px;">
            <p>This email was sent by Al Khazna App</p>
            <p>© 2025 Al Khazna. All rights reserved.</p>
        </div>
    </body>
    </html>
    ''';
  }
}

/// Internal class to store verification data
class _VerificationData {
  final String code;
  final DateTime expiresAt;

  _VerificationData({
    required this.code,
    required this.expiresAt,
  });
}