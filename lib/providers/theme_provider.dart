import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void loadFromUser(UserProfile? userProfile) {
    if (userProfile != null && userProfile.preferences.containsKey('isDarkMode')) {
      bool isDark = userProfile.preferences['isDarkMode'] as bool;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  void toggleTheme(bool isOn, String? uid) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    // Save to Firestore if user is logged in
    if (uid != null) {
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'preferences': {
          'isDarkMode': isOn,
        }
      }, SetOptions(merge: true));
    }
  }
}
