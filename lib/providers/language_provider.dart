
import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('vi');

  Locale get currentLocale => _currentLocale;

  void toggleLanguage() {
    if (_currentLocale.languageCode == 'vi') {
      _currentLocale = const Locale('en');
    } else {
      _currentLocale = const Locale('vi');
    }
    notifyListeners();
  }
}
