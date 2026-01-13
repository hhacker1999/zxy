import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/service/http_service.dart';
import 'package:zxy_app/usecase/auth/user.dart';

class AuthUsecase {
  late final HttpService _httpService;
  final FlutterSecureStorage _storage;

  AuthUsecase(FlutterSecureStorage storage, HttpService service)
    : _storage = storage,
      _httpService = service;

  Future<bool> initialise() async {
    String? st;
    st = await _storage.read(key: "st");

    if (st != null) {
      _httpService.st = st;
    }
    return st != null;
  }

  Future<HttpError?> signup(String name, String email, String password) async {
    final res = await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/signup"),
      body: {"name": name, "email": email, "password": password},
    );
    return res.error;
  }

  Future<(User?, HttpError?)> login(String email, String password) async {
    final res = await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/login"),
      body: {"email": email, "password": password},
    );
    if (res.error != null) {
      return (null, res.error);
    }
    final body = jsonDecode(res.body);
    final user = User.fromJson(body);
    final cookieHeader = res.headers["set-cookie"];
    if (cookieHeader == null) {
      return (null, HttpSomethingWentWrong());
    }
    final cookies = cookieHeader.split("; ");
    if (cookies.isEmpty) {
      return (null, HttpSomethingWentWrong());
    }
    final stCookie = cookies.first.split("=");
    if (stCookie.length != 2) {
      return (null, HttpSomethingWentWrong());
    }
    _httpService.st = stCookie[1];
    await _storage.write(key: "st", value: stCookie[1]);

    return (user, null);
  }

  Future<HttpError?> loginProfile(int profileId) async {
    final res = await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/profile/login"),
      body: {"profile_id": profileId},
      auth: RequestAuth.session,
    );
    if (res.error != null) {
      return res.error;
    }
    final cookieHeader = res.headers["set-cookie"];
    if (cookieHeader == null) {
      throw HttpSomethingWentWrong();
    }
    final cookies = cookieHeader.split("; ");
    if (cookies.isEmpty) {
      throw HttpSomethingWentWrong();
    }
    final stCookie = cookies.first.split("=");
    if (stCookie.length != 2) {
      throw HttpSomethingWentWrong();
    }
    _httpService.pt = stCookie[1];

    return null;
  }

  Future<(User?, HttpError?)> getUser() async {
    final res = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}/user"),
      auth: RequestAuth.session,
    );
    if (res.error != null) {
      return (null, res.error);
    }
    final body = jsonDecode(res.body);
    final user = User.fromJson(body);

    return (user, null);
  }
}
