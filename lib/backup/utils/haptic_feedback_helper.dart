import 'package:flutter/services.dart';

/// Helper class for haptic feedback throughout the app
/// Provides consistent haptic feedback for different user actions
class HapticFeedbackHelper {
  /// Light impact - for subtle feedback (button taps, list scrolling)
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact - for important actions (success, completion)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for critical actions (errors, warnings)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback - for toggle switches, radio buttons
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate feedback - for long operations
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Success feedback - combination of medium impact
  static void success() {
    mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      lightImpact();
    });
  }

  /// Error feedback - combination of heavy impact
  static void error() {
    heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      heavyImpact();
    });
  }

  /// Warning feedback - medium impact
  static void warning() {
    mediumImpact();
  }

  /// Backup start feedback
  static void backupStart() {
    lightImpact();
  }

  /// Backup complete feedback
  static void backupComplete() {
    success();
  }

  /// Restore start feedback
  static void restoreStart() {
    lightImpact();
  }

  /// Restore complete feedback
  static void restoreComplete() {
    success();
  }

  /// Stage change feedback (during backup/restore)
  static void stageChange() {
    lightImpact();
  }

  /// Progress milestone feedback (25%, 50%, 75%)
  static void milestone() {
    lightImpact();
  }
}

