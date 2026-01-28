// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/shared/toast.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthUsecase _authUc;
  String _selectedDebridType = "";
  String get selectedDebridType => _selectedDebridType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController apiKeyController = TextEditingController();

  SettingsViewModel(this._authUc);

  void init(Profile? currentProfile) {
    if (currentProfile != null && currentProfile.debridType.isNotEmpty) {
      _selectedDebridType = currentProfile.debridType;
    }
  }

  Future<void> storeDebridKey(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      if (_selectedDebridType != "tb" && _selectedDebridType != "rd") {
        showToast(context, true, "Invalid debrid provider", "");
        return;
      }
      if (apiKeyController.text.isEmpty) {
        showToast(context, true, "Invalid api key", "");
        return;
      }
      await _authUc.storeUserDebridKey(
        _selectedDebridType,
        apiKeyController.text,
      );
      final newProfile = await _authUc.getUserProfile();
      context.read<UserBloc>().profile = newProfile;
    } catch (e) {
      showToast(context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDebridKey(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authUc.deleteUserDebridKey();
      _selectedDebridType = "";
      final newProfile = await _authUc.getUserProfile();
      context.read<UserBloc>().profile = newProfile;
    } catch (e) {
      showToast(context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDebridType(String type) {
    if (_selectedDebridType != type) {
      _selectedDebridType = type;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    super.dispose();
  }
}
