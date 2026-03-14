import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';

class BaseScaffold extends StatelessWidget {
  final Widget? bottomNavigationBar;
  final Widget Function(BuildContext, Color?) builder;
  final EdgeInsets? padding;
  final ValueNotifier<bool>? loading;
  const BaseScaffold({
    super.key,
    required this.builder,
    this.padding,
    this.loading,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (_, constr) {
          return SizedBox(
            height: constr.maxHeight,
            width: constr.maxWidth,
            child: ValueListenableBuilder(
              valueListenable:context.read<SettingsBloc>().isDynamic,
              builder: (_, dynamic, _) {
                return ValueListenableBuilder(
                  valueListenable: context.read<ImageBloc>().bgGradColor,
                  builder: (_, color, _) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedContainer(
                            padding:
                                padding ?? const EdgeInsets.all(AppTheme.spacingM),
                            duration: const Duration(milliseconds: 500),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors:
                                    color != null &&
                                        dynamic
                                    ? [
                                        color.withOpacity(0.3),
                                        AppTheme.backgroundDark,
                                      ]
                                    : [
                                        AppTheme.backgroundDark,
                                        AppTheme.backgroundDark,
                                      ],
                                stops: color != null ? [0.0, 1.0] : [0.0, 1.0],
                              ),
                            ),
                            child: builder(context, color),
                          ),
                        ),
                        if (loading != null)
                          Positioned.fill(
                            child: ValueListenableBuilder(
                              valueListenable: loading!,
                              builder: (_, val, _) {
                                return Visibility(
                                  visible: val,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                );
              }
            ),
          );
        },
      ),
    );
  }
}
