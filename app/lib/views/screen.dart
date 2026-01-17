import 'package:flutter/material.dart';

class ScreenData {
  final bool shouldRenderMobile;
  final double height;
  final double width;

  const ScreenData({
    required this.shouldRenderMobile,
    required this.height,
    required this.width,
  });
}

class _ScreenScope extends InheritedWidget {
  final ScreenData data;

  const _ScreenScope({required super.child, required this.data});

  @override
  bool updateShouldNotify(covariant _ScreenScope oldWidget) {
    return data.shouldRenderMobile != oldWidget.data.shouldRenderMobile ||
        data.height != oldWidget.data.height ||
        data.width != oldWidget.data.width;
  }
}

class Screen extends StatelessWidget {
  final Widget child;
  const Screen({super.key, required this.child});

  static ScreenData of(BuildContext context) {
    final _ScreenScope? scope = context
        .dependOnInheritedWidgetOfExactType<_ScreenScope>();
    assert(scope != null, "Screen.of() called outside of a Screen widget.");
    return scope!.data;
  }

  bool _updateRenderMobile(BoxConstraints constr) {
    return constr.maxHeight <= 480 || constr.maxWidth <= 600;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constr) {
        return _ScreenScope(
          data: ScreenData(
            shouldRenderMobile: _updateRenderMobile(constr),
            height: constr.maxHeight,
            width: constr.maxWidth,
          ),
          child: child,
        );
      },
    );
  }
}
