// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';

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
    final readToken =
        "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI2NWJjYTJhN2NhODdkNTZkZGZlMDgyZDAzOWNiZjk1ZiIsIm5iZiI6MTY1MDA0MzA3My4wMTksInN1YiI6IjYyNTlhOGMxZWNhZWY1MTVmZjY3OGY3MyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EppXuTBWBa1uXJgfie3m7lKAEpspRwnc_aHr33UBkHU";
    context.read<HomeViewModel>().initialise(readToken).then((_) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.baseHomeView);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Splash View")));
  }
}
