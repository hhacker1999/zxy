// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/shared/toast.dart';

class ProfileSelectionViewModel extends ChangeNotifier {
  final AuthUsecase _authUc;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Profile? _selectedProfile;
  Profile? get selectedProfile => _selectedProfile;

  bool _showPinInput = false;
  bool get showPinInput => _showPinInput;

  final TextEditingController pinController = TextEditingController();

  ProfileSelectionViewModel(this._authUc);

  void selectProfile(BuildContext context, Profile profile) {
    _selectedProfile = profile;
    if (profile.isPinProtected) {
      _showPinInput = true;
      notifyListeners();
    } else {
      _loginProfile(context, profile.id);
    }
  }

  void cancelPinInput() {
    _showPinInput = false;
    _selectedProfile = null;
    pinController.clear();
    notifyListeners();
  }

  Future<void> submitPin(BuildContext context) async {
    if (_selectedProfile == null) return;
    if (pinController.text.length != 6) {
      showToast(context, true, "PIN must be 6 digits", "");
      return;
    }
    await _loginProfile(context, _selectedProfile!.id, pin: pinController.text);
  }

  Future<void> _loginProfile(
    BuildContext context,
    int profileId, {
    String? pin,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authUc.loginProfile(profileId, pin: pin);
      final user = context.read<UserBloc>().userNotifier.value;
      if (user != null) {
        final profile = user.profiles.firstWhere((p) => p.id == profileId);
        context.read<UserBloc>().profile = profile;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.baseHomeView, (route) => false);
    } catch (e) {
      showToast(context, true, e.toString(), "");
      if (pin != null) {
        pinController.clear();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }
}
