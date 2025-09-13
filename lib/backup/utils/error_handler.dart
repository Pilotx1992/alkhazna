import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive error handling for backup operations
class BackupErrorHandler {
  /// Error types from PRD
  static const String noInternet = 'NO_INTERNET';
  static const String signInFailed = 'SIGN_IN_FAILED';
  static const String noBackupFound = 'NO_BACKUP_FOUND';
  static const String decryptionFailed = 'DECRYPTION_FAILED';
  static const String driveQuotaExceeded = 'DRIVE_QUOTA_EXCEEDED';
  static const String uploadFailed = 'UPLOAD_FAILED';

  /// Get user-friendly error message and action
  static BackupErrorInfo getErrorInfo(String errorType, [String? details]) {
    switch (errorType) {
      case noInternet:
        return BackupErrorInfo(
          title: 'No Connection',
          message: 'No connection. Please connect to Wi-Fi and try again.',
          actionText: 'Retry',
          actionType: BackupErrorAction.retry,
          icon: Icons.wifi_off,
        );

      case signInFailed:
        return BackupErrorInfo(
          title: 'Sign-in Failed',
          message: 'Google sign-in failed. Please try again.',
          actionText: 'Sign In',
          actionType: BackupErrorAction.signIn,
          icon: Icons.account_circle_outlined,
        );

      case noBackupFound:
        return BackupErrorInfo(
          title: 'No Backup Found',
          message: 'No backup available for this Google account.',
          actionText: 'OK',
          actionType: BackupErrorAction.dismiss,
          icon: Icons.cloud_off,
        );

      case decryptionFailed:
        return BackupErrorInfo(
          title: 'Backup Error',
          message: 'Could not decrypt backup. The backup may be corrupted.',
          actionText: 'Contact Support',
          actionType: BackupErrorAction.contactSupport,
          icon: Icons.error_outline,
        );

      case driveQuotaExceeded:
        return BackupErrorInfo(
          title: 'Storage Full',
          message: 'Google Drive storage is full. Free up space and try again.',
          actionText: 'Manage Storage',
          actionType: BackupErrorAction.manageStorage,
          icon: Icons.storage,
        );

      case uploadFailed:
        return BackupErrorInfo(
          title: 'Upload Failed',
          message: 'Upload failed. Check your connection and try again.',
          actionText: 'Retry',
          actionType: BackupErrorAction.retry,
          icon: Icons.cloud_upload,
        );

      default:
        return BackupErrorInfo(
          title: 'Error',
          message: details ?? 'An unexpected error occurred. Please try again.',
          actionText: 'OK',
          actionType: BackupErrorAction.dismiss,
          icon: Icons.error,
        );
    }
  }

  /// Check connectivity status
  static Future<bool> hasConnection() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    return !connectivityResults.contains(ConnectivityResult.none);
  }

  /// Show error dialog with appropriate actions
  static Future<void> showErrorDialog(
    BuildContext context,
    String errorType, {
    String? details,
    VoidCallback? onRetry,
    VoidCallback? onSignIn,
    VoidCallback? onContactSupport,
    VoidCallback? onManageStorage,
  }) async {
    final errorInfo = getErrorInfo(errorType, details);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(errorInfo.icon, size: 48, color: Theme.of(context).colorScheme.error),
          title: Text(errorInfo.title),
          content: Text(errorInfo.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleAction(
                  errorInfo.actionType,
                  onRetry: onRetry,
                  onSignIn: onSignIn,
                  onContactSupport: onContactSupport,
                  onManageStorage: onManageStorage,
                );
              },
              child: Text(errorInfo.actionText),
            ),
          ],
        );
      },
    );
  }

  /// Handle error action
  static void _handleAction(
    BackupErrorAction actionType, {
    VoidCallback? onRetry,
    VoidCallback? onSignIn,
    VoidCallback? onContactSupport,
    VoidCallback? onManageStorage,
  }) {
    switch (actionType) {
      case BackupErrorAction.retry:
        onRetry?.call();
        break;
      case BackupErrorAction.signIn:
        onSignIn?.call();
        break;
      case BackupErrorAction.contactSupport:
        onContactSupport?.call();
        break;
      case BackupErrorAction.manageStorage:
        onManageStorage?.call();
        break;
      case BackupErrorAction.dismiss:
        // Do nothing - dialog already dismissed
        break;
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('internet') ||
           errorString.contains('timeout');
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('auth') ||
           errorString.contains('signin') ||
           errorString.contains('permission') ||
           errorString.contains('unauthorized');
  }

  /// Check if error is storage-related
  static bool isStorageError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('quota') ||
           errorString.contains('storage') ||
           errorString.contains('space') ||
           errorString.contains('limit');
  }
}

/// Error information structure
class BackupErrorInfo {
  final String title;
  final String message;
  final String actionText;
  final BackupErrorAction actionType;
  final IconData icon;

  const BackupErrorInfo({
    required this.title,
    required this.message,
    required this.actionText,
    required this.actionType,
    required this.icon,
  });
}

/// Available error actions
enum BackupErrorAction {
  retry,
  signIn,
  dismiss,
  contactSupport,
  manageStorage,
}