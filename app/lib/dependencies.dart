import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/stream/stream.dart';

class Dependencies {
  late final MediaUsecase _mediaUc;
  late final StreamUsecase _streamUc;

  Dependencies() {
    _mediaUc = MediaUsecase();
    _streamUc = StreamUsecase();
  }

  MediaUsecase get mediaUc => _mediaUc;
  StreamUsecase get streamUc => _streamUc;
}
