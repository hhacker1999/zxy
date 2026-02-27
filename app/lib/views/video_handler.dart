import 'package:flutter/foundation.dart';
import 'package:zxy_app/usecase/progress/model.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/view_item_state.dart';

abstract class VideoHandler {
  ValueListenable<ViewItemState<ZxyStreamResponse>> getCurrentStreamsNotifier();
  ValueListenable<WatchProgress> getProgressNotifier();
  ValueNotifier<int> getSelectedStreamNotifier();
  void onProgress(Duration duration);
  void onPause();
  void onPlay();
  void onStop();
  void onDurationUpdate(Duration duration);
  bool isMovie();
  double getStartingPercentage();
  String longTitle();
  String shortTitle();
  Future<String> getStreamUrl(String tempUrl);
}
