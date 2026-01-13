import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/resource/resource.dart';
import 'package:zxy_app/usecase/stream/stream.dart';

class Dependencies {
  late final FlutterSecureStorage _storage;
  late final HttpService _httpService;

  late final MediaUsecase _mediaUc;
  late final StreamUsecase _streamUc;
  late final AuthUsecase _authUc;

  Dependencies() {
    _storage = FlutterSecureStorage();
    _httpService = HttpService();
    _mediaUc = MediaUsecase();
    _streamUc = StreamUsecase();
    _authUc = AuthUsecase(_storage, _httpService);
  }

  MediaUsecase get mediaUc => _mediaUc;
  StreamUsecase get streamUc => _streamUc;
  AuthUsecase get authUc => _authUc;
}
