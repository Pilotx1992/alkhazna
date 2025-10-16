import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app language (English/Arabic)
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  Locale _locale = const Locale('en', '');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isInitialized => _isInitialized;

  /// Initialize language from saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null) {
      _locale = Locale(savedLanguage, '');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle between English and Arabic
  Future<void> toggleLanguage() async {
    _locale = _locale.languageCode == 'en'
        ? const Locale('ar', '')
        : const Locale('en', '');
    await _saveLanguage();
    notifyListeners();
  }

  /// Set language explicitly
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode, '');
    await _saveLanguage();
    notifyListeners();
  }

  /// Save language preference
  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _locale.languageCode);
  }
}
