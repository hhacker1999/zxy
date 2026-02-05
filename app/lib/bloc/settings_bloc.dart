import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/subtitle_style.dart';

class SettingsBloc {
  final ValueNotifier<bool> isAmoled = ValueNotifier(true);
  final ValueNotifier<bool> showPosterRatings = ValueNotifier(true);
  final ValueNotifier<String> recommendedResolution = ValueNotifier("2160p");
  final ValueNotifier<double> volume = ValueNotifier(100);
  late final ValueNotifier<SubtitleFontStyle> subFontStyle;

  set isAmoled(bool amoled) {
    isAmoled.value = amoled;
    _storage.write(key: "amoled", value: amoled.toString());
  }

  set showPosterRatings(bool show) {
    showPosterRatings.value = show;
    _storage.write(key: "poster", value: show.toString());
  }

  set recommendedResolution(String res) {
    recommendedResolution.value = res;
    _storage.write(key: "res", value: res);
  }

  set volume(double vol) {
    volume.value = vol;
    _storage.write(key: "vol", value: vol.toString());
  }

  set subStyle(SubtitleFontStyle style) {
    subFontStyle.value = style;
    _storage.write(key: "size", value: style.fontSize.toString());
    _storage.write(key: "padding", value: style.fontPadding.toString());
  }

  final FlutterSecureStorage _storage;
  SettingsBloc({required FlutterSecureStorage storage}) : _storage = storage;

  Future<void> initialise(BuildContext context) async {
    final isMobile = Screen.of(context).shouldRenderMobile;
    late SubtitleFontStyle style;
    if (isMobile) {
      style = SubtitleFontStyle(
        fontSize: 14,
        fontPadding: 8,
        color: AppTheme.textPrimary,
        bgColor: AppTheme.textBlack,
      );
    } else {
      style = SubtitleFontStyle(
        fontSize: 24,
        fontPadding: 20,
        color: AppTheme.textPrimary,
        bgColor: AppTheme.textBlack,
      );
    }
    final amoled = await _storage.read(key: "amoled");
    final poster = await _storage.read(key: "poster");
    final fontSize = await _storage.read(key: "size");
    final fontPadding = await _storage.read(key: "padding");
    final res = await _storage.read(key: "res");
    final vol = await _storage.read(key: "vol");
    if (amoled != null) {
      isAmoled.value = amoled == "true";
    }

    if (poster != null) {
      showPosterRatings.value = amoled == "true";
    }

    if (res != null) {
      recommendedResolution.value = res;
    }

    if (vol != null) {
      volume.value = double.tryParse(vol) ?? 100;
    }

    if (fontSize != null) {
      style = style.copyWith(fontSize: double.tryParse(fontSize));
    }

    if (fontPadding != null) {
      style = style.copyWith(fontPadding: double.tryParse(fontPadding));
    }

    subFontStyle = ValueNotifier(style);
  }

  void dispose() {
    isAmoled.dispose();
    showPosterRatings.dispose();
    recommendedResolution.dispose();
    subFontStyle.dispose();
  }
}
