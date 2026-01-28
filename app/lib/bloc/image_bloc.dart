import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zxy_app/app_constants.dart';

class ImageData {
  Color? color;
  ColorScheme? scheme;
  final Map<String, ValueNotifier<MemoryImage?>> images;

  ImageData({required this.images});
}

class ImageBloc {
  late final http.Client _client;

  final Map<String, ImageData> _images = {};

  ImageBloc() {
    _client = http.Client();
  }

  final ValueNotifier<Color?> _bgGradColor = ValueNotifier(null);
  ValueListenable<Color?> get bgGradColor => _bgGradColor;

  final ValueNotifier<ColorScheme?> _colorScheme = ValueNotifier(null);
  ValueListenable<ColorScheme?> get colorScheme => _colorScheme;

  Future<void> setGradColorFromImage(String path) async {
    // if (_images.containsKey(path)) {
    //   Color? imgColor = _images[path]!.color;
    //   if (imgColor == null) {
    //     var img = _images[path]!.images.values.firstWhere(
    //       (e) => e.value != null,
    //       orElse: () {
    //         return ValueNotifier(null);
    //       },
    //     );
    //     if (img.value == null) {
    //       return;
    //     }
    //     final color = await _getColorFromImage(img.value!);
    //     _images[path]!.color = color.primary;
    //     _images[path]!.scheme = color;
    //     imgColor = color.primary;
    //   }
    //   _bgGradColor.value = imgColor;
    //   // _colorScheme.value = _images[path]!.scheme;
    // }
  }

  ValueListenable<MemoryImage?> getImage(String size, String path) {
    late final ValueNotifier<MemoryImage?> notifier;
    bool createdNew = false;
    // bool containsColor = false;
    if (_images.containsKey(path)) {
      final info = _images[path]!;
      // containsColor = info.color != null;
      if (info.images.containsKey(size)) {
        notifier = info.images[size]!;
      } else {
        createdNew = true;
        notifier = ValueNotifier(null);
        _images[path]!.images[size] = notifier;
      }
    } else {
      createdNew = true;
      notifier = ValueNotifier(null);
      _images[path] = ImageData(images: {size: notifier});
    }
    if (createdNew) {
      _getImage(size, path, notifier, dontGetColor: true);
    }

    return notifier;
  }

  Future<void> _getImage(
    String size,
    String path,
    ValueNotifier<MemoryImage?> notifier, {
    required bool dontGetColor,
  }) async {
    try {
      final res = await _client.get(
        Uri.parse("${AppConstants.imageConfig.secureBaseUrl}/$size/$path}"),
      );
      if (res.statusCode == 200) {
        if (!dontGetColor) {
          final color = await _getColorFromImage(MemoryImage(res.bodyBytes));
          _images[path]!.color = color.primary;
        }
        notifier.value = MemoryImage(res.bodyBytes);
      } else {
        if (kDebugMode) {
          print("Error getting image: ${res.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting image: $e");
      }
    }
  }

  Future<ColorScheme> _getColorFromImage(MemoryImage image) async {
    final scheme = await ColorScheme.fromImageProvider(
      provider: image,
      brightness: Brightness.dark,
    );
    return scheme;
  }

  void dispose() {
    for (var element in _images.values) {
      for (var notifier in element.images.values) {
        notifier.dispose();
      }
    }
    _bgGradColor.dispose();
    _colorScheme.dispose();
  }
}
