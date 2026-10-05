import 'package:flutter/material.dart';

class NavBarProvider extends ChangeNotifier {
  bool _visible = true;
  bool backPressed = false;
  bool get visible => _visible;

  void hide() {
    // debugPrint('[NAVBAR] hide() called, was visible=$_visible');
    _visible = false;
    notifyListeners();
  }

  void show() {
    // debugPrint('[NAVBAR] show() called, was visible=$_visible');
    _visible = true;
    notifyListeners();
  }
}