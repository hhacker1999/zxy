import 'package:flutter/material.dart';

class BaseHomeViewModel {
  bool _initialsed = false;
  late ValueNotifier<int> selectedIndex;

  ValueNotifier<bool> scaffoldLoading = ValueNotifier(false);

  void initialise() {
    if (_initialsed) {
      dispose();
    }
    selectedIndex = ValueNotifier(0);
    scaffoldLoading = ValueNotifier(false);
    _initialsed = true;
  }

  void dispose() {
    selectedIndex.dispose();
    scaffoldLoading.dispose();
  }
}
