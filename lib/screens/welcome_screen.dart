import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_text_projector_ui/services/websocket_service.dart';
import 'dart:io' show Platform;
import 'dart:convert';

class WelcomeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _WelcomeScreenState();
  }
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  BuildContext? ctx;
  final GlobalKey _key = GlobalKey();
  static bool isSubscribed = false;
  final WebSocketService authService = WebSocketService();

  _WelcomeScreenState();

  @override
  void dispose() {
    print("disposed");
    authService.unsubscribe(onReceiveMessageFromWebSocket);
    super.dispose();
  }

  Future<void> checkToken(BuildContext context) async {

    bool isMobile;
    try {
      isMobile = Platform.isIOS || Platform.isAndroid;
    } catch (e) {
      isMobile = false;
    }

    String? token = await authService.loadToken();
    if (token == null || token.isEmpty) {
      if (context.mounted) {
        if (isMobile) {
          print("going back");
          context.go("/");
        } else {
          print("going back to login");
          context.go("/login");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ctx = context;

    if (!isSubscribed) {
      authService.subscribe(onReceiveMessageFromWebSocket);
      isSubscribed = false;
      print("Subscribed!");
    }

    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.welcome),
          automaticallyImplyLeading: false,
        ),
        body: Center(child: Text(AppLocalizations.of(context)!.hello)),
      ),
    );
  }

  void onReceiveMessageFromWebSocket(String message) {

    bool isMobile;
    try {
      isMobile = Platform.isIOS || Platform.isAndroid;
    } catch (e) {
      isMobile = false;
    }

    final response = jsonDecode(message);
    if (response is Map<String, dynamic>) {
      final context = ctx;
      if (response.containsKey("session_expired") && context != null) {
        if (mounted) {
          if (context.mounted) {
            if (isMobile) {
              print("going back");
              context.go("/");
            } else {
              print("going back to login");
              context.go("/login");
            }
          }
        } else {
          print("Not visible...");
        }
      }
    }
  }


}