import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';

class ZxyImage extends StatefulWidget {
  final String path;
  final String size;
  final void Function(ImageProvider)? onLoad;
  final double? height;
  final double? width;
  final BorderRadius? radius;
  final bool enableShadow;
  final BoxFit fit;
  final bool animate;
  final Widget? replacement;
  const ZxyImage({
    super.key,
    this.onLoad,
    required this.path,
    this.animate = true,
    required this.size,
    this.height,
    this.width,
    this.radius = BorderRadius.zero,
    this.replacement,
    this.enableShadow = false,
    this.fit = BoxFit.fill,
  });

  @override
  State<ZxyImage> createState() => _ZxyImageState();
}

class _ZxyImageState extends State<ZxyImage> {
  bool isCalledLoad = false;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<ImageBloc>().getImage(
        widget.size,
        widget.path,
      ),
      builder: (_, provider, _) {
        if (provider != null) {
          if (!isCalledLoad && widget.onLoad != null) {
            widget.onLoad!(provider);
            isCalledLoad = true;
          }
        }
        return AnimatedContainer(
          duration: widget.animate ? const Duration(seconds: 1) : Duration.zero,
          decoration: BoxDecoration(
            boxShadow: widget.enableShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4), // Subtle dark color
                      blurRadius: 6, // Keeps the shadow close
                      spreadRadius: 1, // Small spread for definition
                      offset: const Offset(0, 3), // Moves shadow slightly down
                    ),
                  ]
                : null,
            borderRadius: widget.radius,
            image:
                provider != null &&
                    widget.height != null &&
                    widget.width != null
                ? DecorationImage(image: provider, fit: widget.fit)
                : null,
          ),
          height: widget.height,
          width: widget.width,
          clipBehavior: widget.height == null && widget.width == null
              ? Clip.antiAlias
              : Clip.none,
          child: provider == null
              ? Align(
                  alignment: widget.replacement != null
                      ? Alignment.bottomLeft
                      : Alignment.center,
                  child:
                      widget.replacement ??
                      SvgPicture.asset(
                        AppIcons.image,
                        color: AppTheme.textSecondary,
                        height: 80,
                        width: 80,
                      ),
                )
              : widget.height == null && widget.width == null
              ? Image(image: provider, fit: widget.fit)
              : null,
        );
      },
    );
  }
}

class LogoZxyImage extends StatefulWidget {
  final String path;
  final String size;
  final double? height;
  final double? maxWidth;
  final BorderRadius? radius;
  final bool enableShadow;
  final BoxFit fit;
  // final bool animate;
  final Widget? replacement;
  final Alignment? alignment;
  const LogoZxyImage({
    super.key,
    required this.path,
    // this.animate = true,
    required this.size,
    this.alignment,
    this.height,
    this.maxWidth,
    this.radius = BorderRadius.zero,
    this.replacement,
    this.enableShadow = false,
    this.fit = BoxFit.fill,
  });

  @override
  State<LogoZxyImage> createState() => _LogoZxyImageState();
}

class _LogoZxyImageState extends State<LogoZxyImage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<ImageBloc>().getImage(
        widget.size,
        widget.path,
      ),
      builder: (_, provider, _) {
        return Container(
          // duration: widget.animate ? const Duration(seconds: 1) : Duration.zero,
          constraints: BoxConstraints(
            maxWidth: widget.maxWidth ?? double.infinity,
          ),
          decoration: BoxDecoration(
            // boxShadow: widget.enableShadow
            //     ? [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.4), // Subtle dark color
            //           blurRadius: 6, // Keeps the shadow close
            //           spreadRadius: 1, // Small spread for definition
            //           offset: const Offset(0, 3), // Moves shadow slightly down
            //         ),
            //       ]
            //     : null,
            borderRadius: widget.radius,
            // image:
            //     provider != null &&
            //         widget.height != null &&
            //         widget.width != null
            //     ? DecorationImage(image: provider, fit: widget.fit)
            //     : null,
          ),
          height: widget.height,
          width: widget.maxWidth,
          clipBehavior: widget.radius != null ? Clip.antiAlias : Clip.none,
          child: Align(
            alignment: widget.replacement != null
                ? widget.alignment ?? Alignment.bottomLeft
                : Alignment.center,
            child: provider != null
                ? Image(
                    image: provider,
                    fit: widget.fit,
                    // height: widget.height,
                    // width: widget.width,
                  )
                : widget.replacement ??
                      SvgPicture.asset(
                        AppIcons.image,
                        color: AppTheme.textSecondary,
                        height: 80,
                        width: 80,
                      ),
          ),
          // : widget.height == null && widget.width == null
          // ? Image(image: provider, fit: widget.fit)
        );
      },
    );
  }
}
