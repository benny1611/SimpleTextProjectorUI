import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_text_projector_ui/services/websocket_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;

class LoginScreen extends StatelessWidget {
  LoginScreen(
      {
        super.key
      });

  final TextEditingController _username_controller = TextEditingController();
  final TextEditingController _password_controller = TextEditingController();
  final WebSocketService authService = WebSocketService();

  void _login(BuildContext context) async {
    bool success;
    String? errorMessage;
    (success, errorMessage) = await authService.login(
      _username_controller.text,
      _password_controller.text,
    );
    if (success) {
      print("login ok");
      context.go('/welcome');
      print("Done");
    } else {
      print("login not ok");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.login_failed)),
      );
      //if (context.mounted) {

      //}
    }
  }

  void _textSubmitted(String text, BuildContext context) async {
    _login(context);
  }

  void _onLoadFunction(BuildContext context) async {
    String? token = await authService.loadToken();
    if (token != null) {
      if (token.isNotEmpty) {
        if (context.mounted) {
          context.go("/welcome");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _onLoadFunction(context);
    bool isMobile;
    try {
      isMobile = Platform.isIOS || Platform.isAndroid;
    } catch (e) {
      isMobile = false;
    }
    return PopScope(
      canPop: isMobile,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.login),
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _username_controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.user_name,
                ),
                onSubmitted: (val) => _textSubmitted(val, context),
              ),
              TextField(
                obscureText: true,
                controller: _password_controller,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                ),
                onSubmitted: (val) => _textSubmitted(val, context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _login(context),
                child: Text(AppLocalizations.of(context)!.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

