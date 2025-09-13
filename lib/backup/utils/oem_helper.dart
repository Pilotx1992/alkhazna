import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// OEM-specific handling for Chinese manufacturers and aggressive battery optimization
class OEMHelper {
  static const List<String> _aggressiveOEMs = [
    'xiaomi',
    'oppo',
    'vivo',
    'huawei',
    'realme',
    'oneplus',
    'honor',
    'meizu',
  ];

  static const List<String> _miuiVariants = ['xiaomi', 'redmi', 'poco'];
  static const List<String> _colorOSVariants = ['oppo', 'realme', 'oneplus'];
  static const List<String> _funTouchVariants = ['vivo', 'iqoo'];

  /// Check if device requires special handling
  static Future<bool> requiresSpecialHandling() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      return _aggressiveOEMs.any((oem) => manufacturer.contains(oem));
    } catch (e) {
      return false; // Default to no special handling if detection fails
    }
  }

  /// Get OEM type for specific handling
  static Future<OEMType> getOEMType() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      if (_miuiVariants.any((oem) => manufacturer.contains(oem))) {
        return OEMType.miui;
      } else if (_colorOSVariants.any((oem) => manufacturer.contains(oem))) {
        return OEMType.colorOS;
      } else if (_funTouchVariants.any((oem) => manufacturer.contains(oem))) {
        return OEMType.funTouchOS;
      } else if (manufacturer.contains('huawei') || manufacturer.contains('honor')) {
        return OEMType.emui;
      } else {
        return OEMType.standard;
      }
    } catch (e) {
      return OEMType.standard;
    }
  }

  /// Request auto-start permission with OEM-specific guidance
  static Future<void> requestAutoStartPermission(BuildContext context) async {
    if (!await requiresSpecialHandling()) return;

    final oemType = await getOEMType();
    
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Battery Optimization'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To ensure reliable auto-backup, please allow this app to run in the background:',
                ),
                const SizedBox(height: 16),
                ...getOEMInstructions(oemType),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openBatterySettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Get OEM-specific instructions
  static List<Widget> getOEMInstructions(OEMType oemType) {
    switch (oemType) {
      case OEMType.miui:
        return [
          const Text('• Settings → Apps → Manage apps → AlKhazna'),
          const Text('• Battery saver → No restrictions'),
          const Text('• Autostart → Enable'),
          const Text('• Background app refresh → Enable'),
        ];
      
      case OEMType.colorOS:
        return [
          const Text('• Settings → Battery → Battery Optimization'),
          const Text('• Find AlKhazna → Don\'t optimize'),
          const Text('• Settings → Privacy & Security → Startup Manager'),
          const Text('• AlKhazna → Enable'),
        ];
      
      case OEMType.funTouchOS:
        return [
          const Text('• Settings → Battery → Background App Refresh'),
          const Text('• Find AlKhazna → Allow'),
          const Text('• Settings → More Settings → Applications'),
          const Text('• AlKhazna → Battery → Allow background activity'),
        ];
      
      case OEMType.emui:
        return [
          const Text('• Settings → Apps → AlKhazna'),
          const Text('• Battery → Manage manually'),
          const Text('• Settings → Battery → Launch'),
          const Text('• AlKhazna → Manage manually (all toggles ON)'),
        ];
      
      case OEMType.standard:
      default:
        return [
          const Text('• Settings → Battery → Battery Optimization'),
          const Text('• Find AlKhazna → Don\'t optimize'),
        ];
    }
  }

  /// Open battery optimization settings
  static Future<void> _openBatterySettings() async {
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      // Fallback: try to open general app settings
      try {
        await Permission.storage.request();
      } catch (e) {
        // If all fails, just continue
      }
    }
  }

  /// Check if WorkManager is likely to be killed
  static Future<bool> isWorkManagerReliable() async {
    final oemType = await getOEMType();
    
    // These OEMs are known to be aggressive with background task killing
    switch (oemType) {
      case OEMType.miui:
      case OEMType.colorOS:
      case OEMType.funTouchOS:
      case OEMType.emui:
        return false; // Not reliable, need fallback
      case OEMType.standard:
      default:
        return true; // Generally reliable
    }
  }

  /// Get recommended backup frequency for OEM
  static Future<String> getRecommendedFrequency() async {
    final oemType = await getOEMType();
    
    switch (oemType) {
      case OEMType.miui:
      case OEMType.colorOS:
      case OEMType.funTouchOS:
      case OEMType.emui:
        return 'Manual backup recommended due to aggressive battery optimization';
      case OEMType.standard:
      default:
        return 'Weekly auto-backup recommended';
    }
  }

  /// Show OEM-specific backup guidance
  static Future<void> showBackupGuidance(BuildContext context) async {
    if (!await requiresSpecialHandling()) return;

    final recommendation = await getRecommendedFrequency();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(recommendation),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => requestAutoStartPermission(context),
          ),
        ),
      );
    }
  }
}

/// OEM types for specific handling
enum OEMType {
  miui,        // Xiaomi, Redmi, POCO
  colorOS,     // Oppo, Realme, OnePlus
  funTouchOS,  // Vivo, iQOO
  emui,        // Huawei, Honor
  standard,    // Stock Android, Samsung, etc.
}