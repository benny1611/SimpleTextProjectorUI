import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_text_projector_ui/services/websocket_service.dart';
import 'dart:io' show Platform;
import 'dart:convert';

import '../widgets/drawing_canvas.dart';

class WelcomeScreen extends StatefulWidget {

  const WelcomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _WelcomeScreenState();
  }
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  BuildContext? ctx;
  static bool isSubscribed = false;
  final WebSocketService authService = WebSocketService();

  _WelcomeScreenState();

  @override
  void dispose() {
    print("disposed");
    authService.unsubscribe(onReceiveMessageFromWebSocket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ctx = context;

    if (!isSubscribed) {
      authService.subscribe(onReceiveMessageFromWebSocket);
      isSubscribed = false;
      print("Subscribed!");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.welcome),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: FutureBuilder<Size>(
            future: authService.getScreenSize(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                final remoteSize = snapshot.data!;
                if (remoteSize.width < 0 || remoteSize.height < 0) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  final Size localSize = MediaQuery.of(context).size;

                  double widthScale = localSize.width / remoteSize.width;
                  double heightScale = localSize.height / remoteSize.height;

                  double scaleFactor = min(widthScale, heightScale);

                  double scaledWidth = remoteSize.width * scaleFactor;
                  double scaledHeight = remoteSize.height * scaleFactor;

                  return DrawingCanvas(
                    width: scaledWidth,
                    height: scaledHeight,
                    scaleFactor: scaleFactor,
                    remoteScreenSize: remoteSize,
                  );
                }
              } else {
                return Text("No data");
              }
            }
        )
      )
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