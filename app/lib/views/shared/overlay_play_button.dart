
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zxy_app/app_constants.dart';

class OverlayPlayButton extends StatelessWidget {
  const OverlayPlayButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            AppIcons.play,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}

