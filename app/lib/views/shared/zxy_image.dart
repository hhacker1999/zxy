import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';

class ZxyImage extends StatefulWidget {
  final String path;
  final String size;
  final bool isPoster;
  final void Function(ImageProvider)? onLoad;
  final double? height;
  final double? width;
  final BorderRadius? radius;
  final bool enableShadow;
  final BoxFit fit;
  const ZxyImage({
    super.key,
    this.onLoad,
    required this.path,
    required this.isPoster,
    required this.size,
    this.height,
    this.width,
    this.radius = BorderRadius.zero,
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
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: provider == null
              ? Container(
                  key: ValueKey("loader"),
                  decoration: BoxDecoration(
                    boxShadow: widget.enableShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.4,
                              ), // Subtle dark color
                              blurRadius: 6, // Keeps the shadow close
                              spreadRadius: 1, // Small spread for definition
                              offset: const Offset(
                                0,
                                3,
                              ), // Moves shadow slightly down
                            ),
                          ]
                        : null,
                    borderRadius: widget.radius,
                  ),
                  height: widget.height,
                  width: widget.width,
                  child: Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      AppIcons.image,
                      color: AppTheme.textSecondary,
                      height: 80,
                      width: 80,
                    ),
                  ),
                )
              : Container(
                  key: ValueKey("image"),
                  decoration: BoxDecoration(
                    boxShadow: widget.enableShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                0.4,
                              ), // Subtle dark color
                              blurRadius: 6, // Keeps the shadow close
                              spreadRadius: 1, // Small spread for definition
                              offset: const Offset(
                                0,
                                3,
                              ), // Moves shadow slightly down
                            ),
                          ]
                        : null,
                    borderRadius: widget.radius,
                    image: DecorationImage(image: provider, fit: widget.fit),
                  ),
                  height: widget.height,
                  width: widget.width,
                ),
        );
      },
    );
  }
}
