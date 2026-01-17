import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/dependencies.dart';
import 'package:zxy_app/views/base_home_view/base_home_view.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/movie_view/movie_view.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/search_view/search_view.dart';
import 'package:zxy_app/views/search_view/search_view_model.dart';
import 'package:zxy_app/views/login_view/login_view.dart';
import 'package:zxy_app/views/login_view/login_view_model.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/fade_page_route.dart';
import 'package:zxy_app/views/splash_view/splash_view.dart';
import 'package:zxy_app/views/splash_view/splash_view_model.dart';
import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class _MyAppState extends State<MyApp> {
  late final Dependencies deps;

  @override
  void initState() {
    super.initState();
    deps = Dependencies();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HomeViewModel>(
          create: (_) => HomeViewModel(tmdbUc: deps.mediaUc, pguc: deps.progUc),
          dispose: (_, model) => model.dispose(),
          lazy: true,
        ),
        Provider<BaseHomeViewModel>(
          create: (_) => BaseHomeViewModel(),
          dispose: (_, model) => model.dispose(),
          lazy: true,
        ),
        Provider<ImageBloc>(
          create: (_) => ImageBloc(),
          dispose: (_, bloc) => bloc.dispose(),
          lazy: false,
        ),
        Provider<UserBloc>(
          create: (_) => UserBloc(),
          dispose: (_, bloc) => bloc.dispose(),
          lazy: false,
        ),
      ],
      builder: (context, _) {
        return MaterialApp(
          builder: (_, child) {
            return Screen(child: child ?? SizedBox.shrink());
          },
          navigatorObservers: [routeObserver],
          title: 'Flutter Demo',
          themeMode: ThemeMode.dark,
          theme: AppTheme.purpleTheme,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AppRoutes.baseHomeView:
                return FadePageRoute(
                  builder: (_) {
                    return BaseHomeView(deps: deps);
                  },
                );
              case AppRoutes.movieView:
                return FadePageRoute(
                  builder: (_) {
                    return Provider(
                      create: (_) => MovieViewModel(
                        mediaUc: deps.mediaUc,
                        streamUc: deps.streamUc,
                        progressUc: deps.progUc,
                      ),
                      dispose: (_, vm) => vm.dispose(),
                      builder: (_, _) =>
                          MovieView(id: settings.arguments as int),
                    );
                  },
                );
              case AppRoutes.showView:
                final args = settings.arguments as int;
                return FadePageRoute(
                  builder: (_) {
                    return Provider(
                      create: (_) => SeriesViewModel(
                        mediaUc: deps.mediaUc,
                        streamUc: deps.streamUc,
                        progressUc: deps.progUc,
                      ),
                      dispose: (_, vm) => vm.dispose(),
                      builder: (_, _) => ShowView(id: args),
                    );
                  },
                );
              case AppRoutes.searchView:
                final args = settings.arguments as String;
                return FadePageRoute(
                  builder: (_) {
                    return Provider(
                      create: (_) => SearchViewModel(mediaUC: deps.mediaUc),
                      dispose: (_, vm) => vm.dispose(),
                      builder: (_, _) => SearchView(keyword: args),
                    );
                  },
                );
              case AppRoutes.loginView:
                return FadePageRoute(
                  builder: (_) {
                    return Provider(
                      create: (_) => LoginViewModel(authUC: deps.authUc),
                      dispose: (_, vm) => vm.dispose(),
                      builder: (_, _) => const LoginView(),
                    );
                  },
                );
              case AppRoutes.videoPlayerView:
                return MaterialPageRoute(
                  builder: (_) {
                    return VideoPlayerView(
                      handler: settings.arguments as VideoHandler,
                    );
                  },
                );
              default:
                return MaterialPageRoute(
                  builder: (_) {
                    return Provider<SplashViewModel>(
                      create: (_) => SplashViewModel(deps.authUc),
                      builder: (_, _) {
                        return SplashView();
                      },
                    );
                  },
                );
            }
          },
          initialRoute: AppRoutes.splash,
        );
      },
    );
  }
}
