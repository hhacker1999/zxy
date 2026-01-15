import 'package:zxy_app/usecase/stream/model.dart';

abstract class VideoHandler {
  List<StreamItem> getCurrentStreams();
  int getSelectedStreamIndex();
  void onProgress(Duration duration);
  void onPause();
  void onPlay();
  void onDurationUpdate(Duration duration);
  bool isMovie();
  double getStartingPercentage();
}
