import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/usecase/auth/user.dart';

class AuthUsecase {
  late final http.Client _client;
  final FlutterSecureStorage _storage;
  late String _profileToken;
  late String _sessionToken;

  AuthUsecase(FlutterSecureStorage storage) : _storage = storage {
    _client = http.Client();
  }

  Future<(String?, String?)> initialise() async {
    String? st;
    String? pt;
    st = await _storage.read(key: "st");
    pt = await _storage.read(key: "pt");

    if (st != null) {
      _sessionToken = st;
      if (pt != null) {
        _profileToken = pt;
      }
    }

    return (st, pt);
  }

  Future<void> signup(String name, String email, String password) async {
    final res = await _client.post(
      Uri.parse("${AppConstants.baseUrl}/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      if (body != null) {
        throw body["error"];
      }
      throw "Invalid status code";
    }
  }

  Future<User> login(String email, String password) async {
    final res = await _client.post(
      Uri.parse("${AppConstants.baseUrl}/login"),
      body: jsonEncode({"email": email, "password": password}),
      headers: {"Content-Type": "application/json"},
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      if (body != null) {
        throw body["error"];
      }
      throw "Invalid status code";
    }
    final user = User.fromJson(body);
    final cookieHeader = res.headers["set-cookie"];
    if (cookieHeader == null) {
      throw "Something went wrong";
    }
    final cookies = cookieHeader.split("; ");
    if (cookies.isEmpty) {
      throw "Something went wrong";
    }
    final stCookie = cookies.first.split("=");
    if (stCookie.length != 2) {
      throw "Something went wrong";
    }
    _sessionToken = stCookie[1];

    return user;
  }

  Future<(String, String)> loginProfile(int profileId) async {
    final res = await _client.post(
      Uri.parse("${AppConstants.baseUrl}/profile/login"),
      body: jsonEncode({"profile_id": profileId}),
      headers: {
        "cookie": "session_token =$_sessionToken",
        "Content-Type": "application/json",
      },
    );
    final body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      if (body != null) {
        throw body["error"];
      }
      throw "Invalid status code";
    }
    final cookieHeader = res.headers["set-cookie"];
    if (cookieHeader == null) {
      throw "Something went wrong";
    }
    final cookies = cookieHeader.split("; ");
    if (cookies.isEmpty) {
      throw "Something went wrong";
    }
    final stCookie = cookies.first.split("=");
    if (stCookie.length != 2) {
      throw "Something went wrong";
    }
    _profileToken = stCookie[1];

    return (_sessionToken, _profileToken);
  }
}
