import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/screen.dart';

void showToast(BuildContext context, bool isError, String title, String desc) {
  final scr = Screen.of(context).shouldRenderMobile;
  toastification.show(
    context: context,
    type: isError ? ToastificationType.error : ToastificationType.success,
    style: ToastificationStyle.flat,
    title: Text(title),
    description: desc.isNotEmpty ? Text(desc) : null,
    alignment: scr ? Alignment.bottomCenter : Alignment.bottomRight,
    autoCloseDuration: const Duration(seconds: 4),
    animationBuilder: (context, animation, alignment, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    backgroundColor: AppTheme.backgroundBlack,
    foregroundColor: Color(0xFFFFFFFF),
    closeButton: ToastCloseButton(showType: CloseButtonShowType.onHover),
    closeOnClick: false,
  );
}
