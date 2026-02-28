// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/views/shared/toast.dart';

class LoginViewModel {
  final AuthUsecase authUC;
  final ValueNotifier<bool> isLoginMode = ValueNotifier(true);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  LoginViewModel({required this.authUC});

  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    error.value = null;
  }

  Future<void> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      if (!_validateEmail(email)) {
        error.value = "Invalid email format";
        return;
      }
      if (password.isEmpty) {
        error.value = "Password cannot be empty";
        return;
      }

      isLoading.value = true;
      error.value = null;
      final user = await authUC.login(email, password);
      debugPrint("Login success: ${user.name}");
      // Navigate to profile selection instead of auto-login
      isLoading.value = false;
      context.read<UserBloc>().user = user;
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.profileSelectionView);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  Future<void> signup(
    BuildContext context,
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      if (name.isEmpty) {
        error.value = "Name cannot be empty";
        return;
      }
      if (!_validateEmail(email)) {
        error.value = "Invalid email format";
        return;
      }
      if (password.isEmpty) {
        error.value = "Password cannot be empty";
        return;
      }
      if (password != confirmPassword) {
        error.value = "Passwords do not match";
        return;
      }
      error.value = null;
      isLoading.value = true;
      error.value = null;
      await authUC.signup(name, email, password);
      isLoading.value = false;
      showToast(
        context,
        false,
        "Sign Up successfull",
        "Please login with your credentials",
      );
      isLoginMode.value = true;
    } catch (e) {
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  bool _validateEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  void dispose() {
    isLoginMode.dispose();
    isLoading.dispose();
    error.dispose();
  }
}
