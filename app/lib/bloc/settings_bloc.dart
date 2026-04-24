import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/subtitle_style.dart';

class SettingsBloc {
  final ValueNotifier<bool> isAmoled = ValueNotifier(true);
  final ValueNotifier<bool> isDynamic = ValueNotifier(true);
  final ValueNotifier<bool> showPosterRatings = ValueNotifier(true);
  final ValueNotifier<bool> showFormattedStreams = ValueNotifier(true);
  final ValueNotifier<double> volume = ValueNotifier(100);
  late final ValueNotifier<SubtitleFontStyle> subFontStyle;
  final ValueNotifier<int> skipDuration = ValueNotifier(30);
  final ValueNotifier<String> langNotifier = ValueNotifier(
    LanguageMapper.defaultLang,
  );
  final ValueNotifier<String> subtitleLangNotifier = ValueNotifier('None');
  final ValueNotifier<bool> autoSelectBestStream = ValueNotifier(true);
  late final ValueNotifier<String> resolutionNotifier;

  set isAmoled(bool amoled) {
    if (amoled) {
      AppTheme.backgroundDark = AppTheme.backgroundBlack;
    } else {
      AppTheme.backgroundDark = AppTheme.darkColor;
    }

    isAmoled.value = amoled;
    _storage.write(key: "amoled", value: amoled.toString());
  }

  set isDynamic(bool dynamic) {
    isDynamic.value = dynamic;
    _storage.write(key: "dynamic", value: dynamic.toString());
  }

  set showPosterRatings(bool show) {
    showPosterRatings.value = show;
    _storage.write(key: "poster", value: show.toString());
  }

  set resolution(String res) {
    resolutionNotifier.value = res;
    _storage.write(key: "resolution", value: res);
  }

  set language(String lang) {
    langNotifier.value = lang;
    _storage.write(key: "language", value: lang);
  }

  set subtitleLanguage(String lang) {
    subtitleLangNotifier.value = lang;
    _storage.write(key: "subtitle_language", value: lang);
  }

  set volume(double vol) {
    volume.value = vol;
    _storage.write(key: "vol", value: vol.toString());
  }

  set skipDuration(int dur) {
    skipDuration.value = dur;
    _storage.write(key: "skipDuration", value: dur.toString());
  }

  set subStyle(SubtitleFontStyle style) {
    subFontStyle.value = style;
    _storage.write(key: "size", value: style.fontSize.toString());
    _storage.write(key: "padding", value: style.fontPadding.toString());
  }

  set showFormattedStreams(bool show) {
    showFormattedStreams.value = show;
    _storage.write(key: "formatted_streams", value: show.toString());
  }

  set setAutoSelectBestStream(bool autoSelect) {
    autoSelectBestStream.value = autoSelect;
    _storage.write(key: "auto_select", value: autoSelect.toString());
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
    final dynamic = await _storage.read(key: "dynamic");
    final poster = await _storage.read(key: "poster");
    final fontSize = await _storage.read(key: "size");
    final fontPadding = await _storage.read(key: "padding");
    final vol = await _storage.read(key: "vol");
    final sd = await _storage.read(key: "skipDuration");
    final lang = await _storage.read(key: "language");
    final subtitleLang = await _storage.read(key: "subtitle_language");
    final resolution = await _storage.read(key: "resolution");
    final formattedStream = await _storage.read(key: "formatted_streams");
    final autoSelect = await _storage.read(key: "auto_select");
    if (amoled != null) {
      isAmoled.value = amoled == "true";
    }

    if (dynamic != null) {
      isDynamic.value = dynamic == "true";
    }

    if (poster != null) {
      showPosterRatings.value = poster == "true";
    }

    if (vol != null) {
      volume.value = double.tryParse(vol) ?? 100;
    }

    if (sd != null) {
      skipDuration.value = int.tryParse(sd) ?? 30;
    }

    if (fontSize != null) {
      style = style.copyWith(fontSize: double.tryParse(fontSize));
    }

    if (fontPadding != null) {
      style = style.copyWith(fontPadding: double.tryParse(fontPadding));
    }

    if (lang != null) {
      langNotifier.value = lang;
    }

    if (subtitleLang != null) {
      subtitleLangNotifier.value = subtitleLang;
    }

    if (formattedStream == "false") {
      showFormattedStreams.value = false;
    }

    if (autoSelect == "false") {
      autoSelectBestStream.value = false;
    }

    if (resolution != null) {
      resolutionNotifier = ValueNotifier(resolution);
    } else {
      if (Platform.isAndroid || Platform.isIOS) {
        resolutionNotifier = ValueNotifier("1080p");
      } else {
        resolutionNotifier = ValueNotifier("2160p");
      }
    }

    subFontStyle = ValueNotifier(style);
  }

  void dispose() {
    isAmoled.dispose();
    showPosterRatings.dispose();
    subFontStyle.dispose();
    skipDuration.dispose();
    resolutionNotifier.dispose();
    langNotifier.dispose();
    subtitleLangNotifier.dispose();
  }
}
