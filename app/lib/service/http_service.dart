import 'dart:convert';
import 'package:http/http.dart' as http;

enum RequestAuth { none, session, profile }

class HttpResponse {
  final HttpError? error;
  final String body;
  late final Map<String, String> headers;

  HttpResponse({this.error, this.body = "", Map<String, String>? hdrs}) {
    headers = hdrs ?? {};
  }
}

abstract class HttpError {
  String get error;
}

class HttpInternalServerError implements HttpError {
  final String _error;

  const HttpInternalServerError({String? error})
    : _error = error ?? "Internal Server Error";

  @override
  String get error => _error;
}

class HttpSomethingWentWrong implements HttpError {
  final String _error;

  const HttpSomethingWentWrong({String? error})
    : _error = error ?? "Something Went Wrong";

  @override
  String get error => _error;
}

class HttpUnAuthorised implements HttpError {
  final String _error;

  const HttpUnAuthorised({String? error}) : _error = error ?? "UnAuthorised";

  @override
  String get error => _error;
}

class HttpBadRequest implements HttpError {
  final String _error;

  const HttpBadRequest({String? error}) : _error = error ?? "Bad Request";

  @override
  String get error => _error;
}

class HttpService {
  late final http.Client _client;
  HttpService() {
    _client = http.Client();
  }

  late final String _st;
  late final String _pt;

  set st(String st) => _st = st;
  set pt(String pt) => _pt = pt;

  Future<HttpResponse> get(
    Uri uri, {
    RequestAuth auth = RequestAuth.none,
  }) async {
    try {
      print("Sending HTTP get request to $uri");
      final res = await _client.get(uri, headers: _getHeaders(auth, false));
      print("Response received with body${res.body}");
      return HttpResponse(
        body: res.body,
        error: _getErrorFromStatusCode(res),
        hdrs: res.headers,
      );
    } catch (e) {
      final err = HttpSomethingWentWrong(error: e.toString());
      return HttpResponse(error: err);
    }
  }

  Future<HttpResponse> post(
    Uri uri, {
    Map<String, dynamic>? body,
    RequestAuth auth = RequestAuth.none,
  }) async {
    try {
      print("Sending HTTP post request to $uri with body $body");
      final res = await _client.post(
        uri,
        body: body != null ? jsonEncode(body) : null,
        headers: _getHeaders(auth, body != null),
      );
      print("Response received with body${res.body}");
      return HttpResponse(
        body: res.body,
        error: _getErrorFromStatusCode(res),
        hdrs: res.headers,
      );
    } catch (e) {
      final err = HttpSomethingWentWrong(error: e.toString());
      return HttpResponse(error: err);
    }
  }

  HttpError? _getErrorFromStatusCode(http.Response res) {
    if (res.statusCode == 401) {
      var body = jsonDecode(res.body);
      final err = HttpUnAuthorised(error: body["error"]);
      return err;
    }
    if (res.statusCode == 500) {
      var body = jsonDecode(res.body);
      final err = HttpInternalServerError(error: body["error"]);
      return err;
    }
    if (res.statusCode == 400) {
      var body = jsonDecode(res.body);
      final err = HttpBadRequest(error: body["error"]);
      return err;
    }
    if (res.statusCode != 200) {
      var body = jsonDecode(res.body);
      final err = HttpSomethingWentWrong(error: body["error"]);
      return err;
    }

    return null;
  }

  Map<String, String>? _getHeaders(RequestAuth auth, bool hasBody) {
    Map<String, String>? res;
    if (auth == RequestAuth.session) {
      res ??= {};
      res["cookie"] = "session_token=$_st";
    }
    if (auth == RequestAuth.profile) {
      res ??= {};
      res["cookie"] = "profile_token=$_pt";
    }
    if (hasBody) {
      res ??= {};
      res["Content-Type"] = "application/json";
    }

    return res;
  }
}
