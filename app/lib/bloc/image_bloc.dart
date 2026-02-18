import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zxy_app/app_constants.dart';
import 'package:image/image.dart' as img;

class ImageData {
  Color? color;
  ColorScheme? scheme;
  final Map<String, ValueNotifier<MemoryImage?>> images;

  ImageData({required this.images});
}

class IsolateImageSendData {
  final Uint8List image;
  final String path;

  const IsolateImageSendData({required this.image, required this.path});
}

class IsolateImageReceiveData {
  final Color color;
  final String path;

  const IsolateImageReceiveData({required this.color, required this.path});
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

  late final SendPort _sp;
  late final Isolate _iso;

  String? lastSentPath;

  Future<void> initialise() async {
    final rPort = ReceivePort();
    _iso = await Isolate.spawn(_isolateWorker, rPort.sendPort);
    final completer = Completer<void>();
    rPort.listen((data) {
      if (data is SendPort) {
        _sp = data;
        completer.complete();
      } else if (data is IsolateImageReceiveData) {
        _images[data.path]!.color = data.color;
        if (lastSentPath == data.path) {
          _bgGradColor.value = data.color;
        }
      }
    });
    return completer.future;
  }

  static void _isolateWorker(SendPort sp) {
    final isolateRp = ReceivePort();
    sp.send(isolateRp.sendPort);
    isolateRp.listen((data) {
      if (data is IsolateImageSendData) {
        final image = img.decodeImage(data.image);
        if (image == null) return;

        // Scale down. 20x20 gives us a slightly better sample pool without hurting performance
        final tinyImage = img.copyResize(image, width: 20, height: 20);

        int r = 0, g = 0, b = 0;
        int count = 0;

        for (final pixel in tinyImage) {
          final pr = pixel.r.toInt();
          final pg = pixel.g.toInt();
          final pb = pixel.b.toInt();

          // Calculate perceived brightness (luminance)
          final luminance = 0.299 * pr + 0.587 * pg + 0.114 * pb;

          // STRICT FILTER: Ignore dark shadows (< 50) and washed-out glare (> 230)
          if (luminance > 50 && luminance < 230) {
            r += pr;
            g += pg;
            b += pb;
            count++;
          }
        }

        // Fallback in case the entire image was pitch black or pure white
        if (count == 0) {
          r = 128;
          g = 128;
          b = 128;
        } else {
          // Average only the "good", visible colors
          r = r ~/ count;
          g = g ~/ count;
          b = b ~/ count;

          // VIBRANCY BOOST: Multiply the final color by 1.2 (20% brighter)
          const double boost = 1.2;
          r = (r * boost).clamp(0, 255).toInt();
          g = (g * boost).clamp(0, 255).toInt();
          b = (b * boost).clamp(0, 255).toInt();
        }

        final dominantColor = Color.fromARGB(255, r, g, b);
        sp.send(IsolateImageReceiveData(color: dominantColor, path: data.path));
      }
    });
  }

  Future<void> setGradColorFromImage(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      return;
    }
    if (_images.containsKey(path)) {
      Color? imgColor = _images[path]!.color;
      if (imgColor == null) {
        var img = _images[path]!.images.values.firstWhere(
          (e) => e.value != null,
          orElse: () {
            return ValueNotifier(null);
          },
        );
        if (img.value == null) {
          return;
        }
        lastSentPath = path;
        _sp.send(IsolateImageSendData(image: img.value!.bytes, path: path));
      } else {
        _bgGradColor.value = imgColor;
      }
    }
  }

  ValueNotifier<MemoryImage?> getImage(
    String size,
    String path, {
    bool cache = true,
  }) {
    late final ValueNotifier<MemoryImage?> notifier;
    bool createdNew = false;
    if (_images.containsKey(path)) {
      final info = _images[path]!;
      if (info.images.containsKey(size)) {
          notifier = info.images[size]!;
      } else {
        createdNew = true;
        notifier = ValueNotifier(null);
        if (cache) {
          _images[path]!.images[size] = notifier;
        }
      }
    } else {
      createdNew = true;
      notifier = ValueNotifier(null);
      if (cache) {
        _images[path] = ImageData(images: {size: notifier});
      }
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

  static Future<ColorScheme> _getColorFromImage(MemoryImage image) async {
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
    _iso.kill();
  }
}
