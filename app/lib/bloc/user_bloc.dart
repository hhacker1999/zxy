import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/auth/user.dart';

class UserBloc {
  final ValueNotifier<User?> _userNotifier = ValueNotifier(null);

  ValueListenable<User?> get userNotifier => _userNotifier;

  final ValueNotifier<Profile?> _profileNotifier = ValueNotifier(null);

  ValueListenable<Profile?> get profileNotifier => _profileNotifier;

  set user(User user) => _userNotifier.value = user;
  set profile(Profile f) => _profileNotifier.value = f;

  void dispose() {
    _userNotifier.dispose();
  }
}
