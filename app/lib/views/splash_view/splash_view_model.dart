// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
// import 'package:zxy_app/service/http_proxy.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/shared/toast.dart';

class SplashViewModel {
  final AuthUsecase authUc;

  const SplashViewModel(this.authUc);

  Future<void> initialise(BuildContext context) async {
    try {
      print("in initialise");
      await context.read<ImageBloc>().initialise();
      print("after image");
      await context.read<SettingsBloc>().initialise(context);
      print("after settings");
      // await context.read<ProxyManager>().startProxyManager();
      await Future.wait([
        context.read<HomeViewModel>().initialiseGenre(),
        context.read<HomeViewModel>().initialiseConfig(),
      ]);
      print("after config");
      var res = await authUc.initialise();
      print("after auth");
      if (!res) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginView);
        return;
      }
      var userRes = await authUc.getUser();
      var userProfile = await authUc.getUserProfile();
      context.read<UserBloc>().user = userRes;
      context.read<UserBloc>().profile = userProfile;
      Navigator.pushReplacementNamed(context, AppRoutes.baseHomeView);
    } catch (e) {
      if (e is HttpUnAuthorised) {
        Navigator.pushReplacementNamed(context, AppRoutes.loginView);
        return;
      }
      showToast(context, true, e.toString(), "");
      rethrow;
    }
  }
}
