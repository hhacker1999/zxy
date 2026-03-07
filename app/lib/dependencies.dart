import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/service/web_socket.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/progress/usecase.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/stream/stream.dart';

class Dependencies {
  late final FlutterSecureStorage _storage;
  late final HttpService _httpService;
  late final WebSocketService _wsService;

  late final MediaUsecase _mediaUc;
  late final StreamUsecase _streamUc;
  late final AuthUsecase _authUc;
  late final ProgressUsecase _progressUc;

  Dependencies() {
    _storage = FlutterSecureStorage();
    _httpService = HttpService();
    _mediaUc = MediaUsecase(_httpService);
    _streamUc = StreamUsecase(_httpService);
    _progressUc = ProgressUsecase(service: _httpService);
    _wsService = WebSocketService();
    _authUc = AuthUsecase(_storage, _httpService, _wsService);
  }

  FlutterSecureStorage get storage => _storage;
  WebSocketService get wsService => _wsService;

  MediaUsecase get mediaUc => _mediaUc;
  StreamUsecase get streamUc => _streamUc;
  AuthUsecase get authUc => _authUc;
  ProgressUsecase get progUc => _progressUc;
}
