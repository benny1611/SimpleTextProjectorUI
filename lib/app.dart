import 'package:flutter/material.dart';
import 'package:simple_text_projector_ui/screens/login_screen.dart';
import 'package:simple_text_projector_ui/screens/pre_login_screen.dart';
import 'package:simple_text_projector_ui/screens/welcome_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:go_router/go_router.dart';

class SimpleTextProjectorUI extends StatelessWidget {

  SimpleTextProjectorUI({super.key});

  String getInitialLocation() {
    bool isMobile;
    try {
      isMobile = Platform.isAndroid || Platform.isIOS;
    } catch(e) {
      isMobile = false;
    }
    if (isMobile) {
      return "/";
    } else {
      return "/login";
    }
  }

  @override
  Widget build(BuildContext context) {

    final GoRouter router = GoRouter(
        initialLocation: getInitialLocation(),
        routes: [
          GoRoute(
            path: "/",
            builder: (context, state) => PreLoginScreen(),
          ),
          GoRoute(
            path: "/login",
            builder: (context, state) => LoginScreen(),
          ),
          GoRoute(
            path: "/welcome",
            builder: (context, state) => WelcomeScreen(),
          )
        ]
    );

    return MaterialApp.router(
      routerConfig: router,
      title: 'Simple Text Projector',
      theme: ThemeData(primarySwatch: Colors.blue),
      supportedLocales: const [Locale('en', ''), Locale('es', '')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
    );
  }
}
