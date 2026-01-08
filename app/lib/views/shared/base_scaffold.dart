import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';

class BaseScaffold extends StatelessWidget {
  final Widget Function(BuildContext, Color?) builder;
  const BaseScaffold({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: context.read<ImageBloc>().bgGradColor,
        builder: (_, color, _) {
          return AnimatedContainer(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            duration: const Duration(milliseconds: 500),
            height: double.maxFinite,
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: color != null
                    ? [color.withOpacity(0.3), AppTheme.backgroundDark]
                    : [AppTheme.backgroundDark, AppTheme.backgroundDark],
                stops: color != null ? [0.0, 1.0] : [0.0, 1.0],
              ),
            ),
            child: builder(context, color),
          );
        },
      ),
    );
  }
}
