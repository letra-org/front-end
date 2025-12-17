import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('vi');

  LanguageProvider() {
    _loadLocale();
  }

  Locale get currentLocale => _currentLocale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'vi';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  void toggleLanguage() {
    if (_currentLocale.languageCode == 'vi') {
      _currentLocale = const Locale('en');
      _saveLocale('en');
    } else {
      _currentLocale = const Locale('vi');
      _saveLocale('vi');
    }
    notifyListeners();
  }
}
