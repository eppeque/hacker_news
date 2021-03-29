import 'package:flutter/material.dart';

/// Class to dynamically toggle the theme. Works with the [ChangeNotifierProvider] widget in the main function.
class ThemeProvider with ChangeNotifier {
  bool isDarkTheme;

  ThemeProvider({required this.isDarkTheme});

  ThemeData get theme => isDarkTheme ? darkTheme : lightTheme;

  set setTheme(bool val) {
    if (val) {
      isDarkTheme = true;
    } else {
      isDarkTheme = false;
    }
    notifyListeners();
  }
}

final _blue = Color(0xFF4885ed);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  accentColor: _blue,
  fontFamily: 'Google Sans',
);

final lightTheme = ThemeData(
  primaryColor: Colors.white,
  accentColor: _blue,
  scaffoldBackgroundColor: Colors.white,
  canvasColor: Colors.white,
  fontFamily: 'Google Sans',
);