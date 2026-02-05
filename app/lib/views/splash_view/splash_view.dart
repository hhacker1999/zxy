// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/splash_view/splash_view_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    initialise();
  }

  void initialise() async {
    MediaKit.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<SplashViewModel>().initialise(context);
      if (Screen.of(context).isMobileDevice) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await windowManager.ensureInitialized();
        WindowOptions windowOptions = WindowOptions(
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Scaffold(
      body: Center(
        child: Image.asset(
          AppIcons.logo,
          height: screenData.shouldRenderMobile ? 150 : 250,
          width: screenData.shouldRenderMobile ? 150 : 250,
        ),
      ),
    );
  }
}
