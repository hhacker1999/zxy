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
    String? pt;
    st = await _storage.read(key: "st");
    pt = await _storage.read(key: "pt");

    if (st != null) {
      _httpService.st = st;
    }

    if (pt != null) {
      _httpService.pt = pt;
    }
    return st != null && pt != null;
  }

  Future<void> signup(String name, String email, String password) {
    return _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/signup"),
      body: {"name": name, "email": email, "password": password},
    );
  }

  Future<User> login(String email, String password) async {
    final res = await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/login"),
      body: {"email": email, "password": password},
    );
    final body = jsonDecode(res.body);
    final user = User.fromJson(body);
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
    _httpService.st = stCookie[1];
    await _storage.write(key: "st", value: stCookie[1]);

    return user;
  }

  Future<void> loginProfile(int profileId, {String? pin}) async {
    final body = {"profile_id": profileId, if (pin != null) "pin": pin};
    final res = await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/profile/login"),
      body: body,
      auth: RequestAuth.session,
    );
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
    await _storage.write(key: "pt", value: stCookie[1]);
  }

  Future<User> getUser() async {
    final res = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}/user"),
      auth: RequestAuth.session,
    );
    final body = jsonDecode(res.body);
    final user = User.fromJson(body);
    return user;
  }

  Future<Profile> getUserProfile() async {
    final res = await _httpService.get(
      Uri.parse("${AppConstants.baseUrl}/user/profile"),
      auth: RequestAuth.profile,
    );
    final body = jsonDecode(res.body);
    final profile = Profile.fromJson(body);
    return profile;
  }

  Future<void> storeUserDebridKey(String tp, String key) async {
    await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/user/debrid/api"),
      auth: RequestAuth.profile,
      body: {"debrid_type": tp, "api_key": key},
    );
  }

  Future<void> deleteUserDebridKey() async {
    await _httpService.delete(
      Uri.parse("${AppConstants.baseUrl}/user/debrid/api"),
      auth: RequestAuth.profile,
    );
  }

  Future<void> createProfile(String name, String? pin, bool copyKey) async {
    await _httpService.post(
      Uri.parse("${AppConstants.baseUrl}/user/profile"),
      auth: RequestAuth.profile,
      body: {
        "name": name,
        "use_default_profile_key": copyKey,
        "pin": pin ?? "",
      },
    );
  }

  Future<void> updateProfile(String name, String? pin, int profileId) async {
    await _httpService.put(
      Uri.parse("${AppConstants.baseUrl}/user/profile"),
      auth: RequestAuth.profile,
      body: {"name": name, "profile_id": profileId, "pin": pin ?? ""},
    );
  }

  Future<void> updateProfileList(List<ProfileLibraryItem> list) async {
    await _httpService.put(
      Uri.parse("${AppConstants.baseUrl}/user/profile/list"),
      auth: RequestAuth.profile,
      body: list.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> deleteProfile(int profileId) async {
    await _httpService.delete(
      Uri.parse("${AppConstants.baseUrl}/user/profile?profile_id=$profileId"),
      auth: RequestAuth.profile,
    );
  }
}
