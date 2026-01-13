// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
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
    MediaKit.ensureInitialized();
    context.read<SplashViewModel>().initialise(context);
    // if (context.mounted) {
    //   Navigator.pushReplacementNamed(context, AppRoutes.baseHomeView);
    // }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Splash View")));
  }
}
