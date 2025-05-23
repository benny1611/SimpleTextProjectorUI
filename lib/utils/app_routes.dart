import 'package:flutter/material.dart';
import 'package:simple_text_projector_ui/screens/login_screen.dart';
import 'package:simple_text_projector_ui/screens/welcome_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginScreen(),
  '/welcome': (context) => WelcomeScreen(),
};
