import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:zxy_app/app_constants.dart';

class WebSocketService {
  late String _token;
  WebSocket? _currentSocket;
  final Map<String, StreamController> _messageToControllerMap = {};
  DateTime? _lastPong;
  Timer? _pingTimer;
  DateTime? _lastConnectTryTime;
  bool _connectInProgress = false;

  Future<void> connect(String token) async {
    if (_currentSocket != null) {
      print("Closing current socket");
      _pingTimer?.cancel();
      await _currentSocket!.close();
    }
    _token = token;
    return _connect();
  }

  Future<void> _connect() async {
    if (_connectInProgress) return;
    try {
      _connectInProgress = true;
      _lastConnectTryTime = DateTime.now();
      _currentSocket = await WebSocket.connect(
        AppConstants.wsUrl,
        headers: {
          "cookie": "profile_token=$_token",
          'User-Agent': 'Dart-Client-1.0',
        },
      );
      _currentSocket!.listen(
        (data) {
          print(data);
          if (data == "pong") {
            _lastPong = DateTime.now();
            return;
          }
          print(data);
          final mapData = jsonDecode(data) as Map<String, dynamic>;
          final type = mapData["type"];
          if (type == null) {
            print("Type not present in message");
            return;
          }
          final controller = _messageToControllerMap[type];
          if (controller != null) {
            controller.add(mapData["data"]);
          } else {
            print("No Controller found for message type");
          }
        },
        cancelOnError: true,
        onDone: () {
          print("Connection closed");
        },
        onError: (e) {
          print("Error from socket $e");
          _reconnect();
        },
      );
      _startPingTimer();
      _connectInProgress = false;
    } catch (e) {
      print("Error connecting to websocket $e");
      _connectInProgress = false;
      _reconnect();
    }
  }

  Future<void> _reconnect() async {
    final sinceLastTry = DateTime.now().difference(_lastConnectTryTime!);
    if (_lastConnectTryTime != null && sinceLastTry < Duration(seconds: 5)) {
      await Future.delayed(Duration(seconds: 5) - sinceLastTry);
    }

    _pingTimer?.cancel();
    print("Reconnecting to socket");
    await _currentSocket?.close();
    _currentSocket = null;
    _connect();
  }

  void _startPingTimer() {
    print("Starting ping timer");
    _lastPong = DateTime.now();
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_lastPong != null) {
        if (DateTime.now().difference(_lastPong!) > Duration(seconds: 10)) {
          print("Have not received pong from last ping");
          _reconnect();
          return;
        }
      }
      _currentSocket!.add("ping");
    });
  }

  void sendMessage(dynamic message) {
    if (_currentSocket != null) {
      _currentSocket!.add(message);
    }
  }

  bool isConnected() {
    return _currentSocket != null;
  }

  StreamController registerHandler(String type) {
    final StreamController controller = StreamController();
    _messageToControllerMap[type] = controller;
    return controller;
  }

  void clean() {
    _currentSocket == null;
    _currentSocket?.close();
    _pingTimer?.cancel();
    for (var element in _messageToControllerMap.entries) {
      element.value.close();
    }
  }
}
