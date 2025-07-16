import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';

class WebSocketService {

  static WebSocketChannel? _channel;
  static Completer<String?> completer = Completer<String?>();
  static String? error;
  static Timer? _timer;
  final _storage = FlutterSecureStorage();
  final List<Function(String)> subscribers = [];
  final Map<String, Completer<dynamic>> completers = {};

  WebSocketService._privateConstructor();

  static final WebSocketService _instance = WebSocketService._privateConstructor();

  WebSocketService.internal() {
    _connect();
  }

  factory WebSocketService() {
    return _instance;
  }

  Future<dynamic> sendCommand(Map<String, dynamic> command, String waitForKey) async {
    final commandAsJson = jsonEncode(command);

    Completer<dynamic> compl = _sendMessageAndGetCompleter(commandAsJson, waitForKey);

    return await compl.future;
  }

  /// Function to login
  ///
  /// @username the username
  /// @password the password
  ///
  /// returns (success (bool), error(String?)): success: whether the login was successful or not; error: error message, null if no error
  Future<(bool, String?)> login(String username, String password) async {

    const String env = String.fromEnvironment('ENV', defaultValue: 'PROD');
    if (env == 'DEV-NO-LOGIN') {
      return (true, "test");
    }

    if (_channel == null) {
      _connect();
    }

    _sendUserAndPass(username, password);

    if (! _timer!.isActive) {
      _startTimer();
    }
    completer = Completer<String?>();

    final timeout = Future.delayed(Duration(seconds: 1), () => null);
    String? token = await Future.any([completer.future, timeout]);

    if (token != null) {
      _saveToken(token);
    }
    return (token != null, error);
  }

  // Save session token securely
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'session_token', value: token);  // Save token
  }

  // Retrieve session token securely
  Future<String?> loadToken() async {
    String? token = await _storage.read(key: 'session_token');
    return token;
  }

  // Delete session token (for example, on logout)
  Future<void> _deleteToken() async {
    await _storage.delete(key: 'session_token');
  }

  void _connectWebSocket(String hostAndPort) {
    _channel = WebSocketChannel.connect(
      Uri.parse("ws://$hostAndPort"),
    );

    // Listen for incoming messages
    _channel!.stream.listen((message) {
      print("Got a message: $message");
      try {
        final response = jsonDecode(message);
        if (response is Map<String, dynamic>) {
          if (response.containsKey("session_token")) {
            completer.complete(response["session_token"]);
          }
          List<String> keysToRemove = [];
          for (String s in completers.keys) {
            if (response.containsKey(s)) {
              print("Completing...");
              completers[s]?.complete(response);
              keysToRemove.add(s);
            }
          }
          for (String s in keysToRemove) {
            completers.remove(s);
          }
          keysToRemove.clear();

          if (response.containsKey("error")) {
            error = response["message"];
            if (response.containsKey("error_type")) {
              String error_type = response["error_type"];
              switch (error_type) {
                case "session_error":
                case "auth_error":
                  _backToLogin();
                  break;
                case "color_error":
                case "font_size_error":
                case "font_error":
                case "stream_error":
                case "get_error":
                case "set_error":
                case "monitor_error":
                case "registration_error":
                case "text_error":
                  // ignore
                  break;
              }
            }
          }
        }
      } catch (e) {
        print("Failed to decode JSON: $message");
        print(e);
      }
    }, onError: (error) {
      print("Error: $error");
      _channel?.sink.close();
      _channel = null;
      _backToLogin();
    }, onDone: () {
      print("WebSocket closed");
      _channel = null;
      _backToLogin();
    });
  }

  void _connect() {
    Uri uri;
    if(kIsWeb) {
      const String env = String.fromEnvironment('ENV', defaultValue: 'PROD');
      if (env == 'DEV') {
        uri = Uri.parse("http://localhost");
      } else {
        uri = Uri.base;
      }
    } else {
      // TODO: implement URL fetching for mobile / PC
      uri = Uri.parse("unknown");
    }

    String hostAndPort = uri.host;
    if(uri.hasPort) {
      hostAndPort += ':${uri.port}';
    }
    _connectWebSocket(hostAndPort);
    _startTimer();
  }

  void _startTimer() {
    _timer ??= Timer.periodic(Duration(seconds: 25), (Timer timer) {
      _sendPingMessage();
    });
  }

  void _sendUserAndPass(String user, String pass) {
    if (_channel != null) {
      final message = {
        "authenticate" : {
          "user": user,
          "password": pass
        }
      };
      final String messageString = jsonEncode(message);
      _sendMessage(messageString);
    }
  }

  void _sendPingMessage() {
    if (_channel != null) {
      final message = {
        'get': 'ping'
      };

      final jsonString = jsonEncode(message);
      _sendMessage(jsonString);
    }

  }

  void _sendMessage(String message) {
    print("Sending: $message");
    _channel!.sink.add(message);
  }

  Completer<dynamic> _sendMessageAndGetCompleter(String message, String waitForKey) {
    print("Sending and waiting: $message");
    Completer<dynamic> cmpl = new Completer();
    completers[waitForKey] = cmpl;
    Future.delayed(Duration(seconds: 1), () {
      if (!cmpl.isCompleted) {
        cmpl.completeError('TIMEOUT');
      }
    });

    _sendMessage(message);

    return cmpl;
  }

  void subscribe(Function(String) subscriber) {
    subscribers.add(subscriber);
  }

  void unsubscribe(Function(String) subscriber) {
    subscribers.remove(subscriber);
  }

  void _publishMessage(String message) {
    for (void Function(String) sub in subscribers) {
      sub(message);
    }
  }

  void _backToLogin() {
    _deleteToken();
    final msg = {
      "session_expired": true
    };
    _publishMessage(jsonEncode(msg));
    _timer?.cancel();
  }

  Future<Size> getScreenSize() async {
    Size screenSize = Size(-1,-1);

    final getScreenSizeMessage = {
      'get': 'screen_size'
    };

    final screenSizeMessageAsJSON = jsonEncode(getScreenSizeMessage);

    Completer<dynamic> compl = _sendMessageAndGetCompleter(screenSizeMessageAsJSON, "refresh_rate");

    dynamic response = await compl.future;
    if(response is Map<String, dynamic>) {
      if (response.containsKey("width") && response.containsKey("height")) {
        screenSize = Size(response["width"], response["height"]);
      }
    }

    return screenSize;
  }

}
