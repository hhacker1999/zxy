import 'package:flutter/material.dart';

class BaseHomeViewModel {
  final ValueNotifier<int> selectedIndex = ValueNotifier(0);
  void dispose() {
    selectedIndex.dispose();
  }
}
