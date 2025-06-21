import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index && index >= 0 && index <= 3) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() => setIndex(0);
  void goToHistory() => setIndex(1);
  void goToNotifications() => setIndex(2);
  void goToSettings() => setIndex(3);
}