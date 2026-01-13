// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';

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
    if (user.$2 != null) {
      error.value = user.$2!.error;
      isLoading.value = false;
      return;
    }
    debugPrint("Login success: ${user.$1!.name}");
    final profileErr = await authUC.loginProfile(user.$1!.profiles.first.id);
    if (profileErr != null) {
      error.value = profileErr.error;
      isLoading.value = false;
      return;
    }
    debugPrint("Profile Login success");
    isLoading.value = false;
    context.read<UserBloc>().user = user.$1!;
    Navigator.of(context).pushReplacementNamed(AppRoutes.baseHomeView);
  }

  Future<void> signup(
    BuildContext context,
    String name,
    String email,
    String password,
    String confirmPassword,
  ) async {
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

    isLoading.value = true;
    error.value = null;
    final err = await authUC.signup(name, email, password);
    if (err == null) {
      debugPrint("Signup success");
    }
    error.value = err?.error;
    isLoading.value = false;
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
