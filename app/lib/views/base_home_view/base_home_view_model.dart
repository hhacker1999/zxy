import 'package:flutter/material.dart';

class BaseHomeViewModel {
  bool _initialsed = false;
  late ValueNotifier<int> selectedIndex;

  void initialise() {
    if (_initialsed) {
      dispose();
    }
    selectedIndex = ValueNotifier(0);
    _initialsed = true;
  }

  void dispose() {
    selectedIndex.dispose();
  }
}
