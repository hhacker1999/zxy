import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/auth/user.dart';

class UserBloc {
  final ValueNotifier<User?> _userNotifier = ValueNotifier(null);

  ValueListenable<User?> get userNotifier => _userNotifier;

  set user(User user) => _userNotifier.value = user;

  void dispose() {
    _userNotifier.dispose();
  }
}
