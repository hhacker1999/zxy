import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:zxy_app/usecase/stream/model.dart';

class VideoPlayerInput {
  final List<StreamItem> streams;
  final int index;
  VideoPlayerInput({required this.streams, required this.index});
}

class VideoPlayerView extends StatefulWidget {
  final VideoPlayerInput input;
  const VideoPlayerView({super.key, required this.input});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.input.streams[widget.input.index].url));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Video(controller: _controller, controls: MaterialVideoControls),
      ),
    );
  }
}
