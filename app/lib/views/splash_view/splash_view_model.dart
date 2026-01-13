// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';

class SplashViewModel {
  final AuthUsecase authUc;

  const SplashViewModel(this.authUc);

  Future<void> initialise(BuildContext context) async {
    await Future.wait([
      context.read<HomeViewModel>().initialiseGenre(),
      context.read<HomeViewModel>().initialiseConfig(),
    ]);
    var res = await authUc.initialise();
    if (!res) {
      Navigator.pushReplacementNamed(context, AppRoutes.loginView);
      return;
    }
    var userRes = await authUc.getUser();
    if (userRes.$2 != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.loginView);
      return;
    }
    context.read<UserBloc>().user = userRes.$1!;
    Navigator.pushReplacementNamed(context, AppRoutes.baseHomeView);
  }
}
