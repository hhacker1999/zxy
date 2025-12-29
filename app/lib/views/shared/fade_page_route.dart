import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget Function(BuildContext) builder;
  final Duration fadeDuration;

  FadePageRoute({
    required this.builder,
    this.fadeDuration = const Duration(milliseconds: 400),
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: fadeDuration,
         reverseTransitionDuration: fadeDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // final curvedAnimation = CurvedAnimation(
           //   parent: animation,
           //   curve: Curves.easeIn,
           // );
           return FadeTransition(
             opacity: animation,
             child: ScaleTransition(
               // Starts at 98% size and scales to 100%
               scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOut),
               ),
               child: child,
             ),
           );

           // return FadeTransition(opacity: curvedAnimation, child: child);
         },
       );
}
