import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class StartMessage {}

class KillMessage {}

class UrlMessage {
  final String url;

  const UrlMessage(this.url);
}

class StartedMessage {}

class ProxyManager {
  late final Isolate _isolate;

  late final ReceivePort _rp;

  SendPort? _sp;

  Future<void> startProxyManager() {
    final completer = Completer<void>();
    _rp = ReceivePort();

    _internalStart(completer);
    return completer.future.timeout(Duration(seconds: 10));
  }

  void setInternalUrl(String url) {
    if (_sp == null) {
      throw "Uninitialised error";
    }
    _sp!.send(UrlMessage(url));
  }

  void _internalStart(Completer<void> cmp) async {
    _isolate = await Isolate.spawn(_startProxy, _rp.sendPort);
    _rp.listen((data) {
      if (data is SendPort) {
        _sp = data;
        _sp!.send(StartMessage());
      }
      if (data is StartedMessage) {
        cmp.complete();
      }
    });
  }

  static void _startProxy(SendPort sp) {
    late final RedirectAwareProxy proxy;
    final rp = ReceivePort();

    sp.send(rp.sendPort);
    rp.listen((message) async {
      if (message is StartMessage) {
        proxy = RedirectAwareProxy(port: 6969);
        await proxy.startHttpServer();
        sp.send(StartedMessage());
      }
      if (message is UrlMessage) {
        proxy.updateUrl(message.url);
      }
      if (message is KillMessage) {
        proxy.dispose();
      }
    });
  }

  void dispose() {
    _sp?.send(KillMessage());
    Future.delayed(Duration(milliseconds: 200), () => _isolate.kill());
  }
}

class RedirectAwareProxy {
  String? initialUrl; // The backend URL
  String? _finalResolvedUrl; // final debrid url we get from server
  final int port;
  HttpServer? _server;

  final _client = HttpClient();

  RedirectAwareProxy({this.port = 6969});

  void updateUrl(String url) async {
    if (initialUrl != null && initialUrl == url) {
      return;
    }
    initialUrl = url;
    _finalResolvedUrl = null;
  }

  Future<void> startHttpServer() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

    _server!.listen((HttpRequest request) async {
      await _proxyRequest(request, "");
    });
  }

  Future<void> _proxyRequest(HttpRequest request, String range) async {
    print("Using url ${_finalResolvedUrl ?? initialUrl}");
    final forwardRequest = await _client.openUrl(
      request.method,
      Uri.parse(_finalResolvedUrl ?? initialUrl!),
    );

    forwardRequest.followRedirects = true;
    forwardRequest.maxRedirects = 10;
    request.headers.forEach((name, values) {
      if (name != 'host' && name != 'connection' && name != 'keep-alive') {
        for (var value in values) {
          forwardRequest.headers.add(name, value);
        }
      }
    });

    final forwardResponse = await forwardRequest.close();
    if (forwardResponse.redirects.isNotEmpty) {
      _finalResolvedUrl = forwardResponse.redirects.last.location.toString();
      print("Final url stored here $_finalResolvedUrl");
    }
    request.response.statusCode = forwardResponse.statusCode;

    forwardResponse.headers.forEach((name, values) {
      final k = name.toLowerCase();
      if (k != 'transfer-encoding' &&
          k != 'connection' &&
          k != "content-disposition") {
        request.response.headers.removeAll(name);
        for (var value in values) {
          request.response.headers.add(name, value);
        }
      }
    });

    await request.response.flush();

    await request.response.addStream(forwardResponse);
    await request.response.close();
  }

  Future<void> dispose() async {
    await _server?.close();
    _client.close();
  }
}
