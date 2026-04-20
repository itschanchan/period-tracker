import 'package:flutter/material.dart';

import '/login_screen.dart';
import '/register_screen.dart';
import '/dashboard/dashboard_screen.dart';

class AppRoutes {
  AppRoutes._(); // Private constructor

  static const String root = '/'; // standalone backlash indicates landing page.
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String register = '/register';

  static Map<String, WidgetBuilder> define() {
    return {
      root: (context) => const LoginScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => const DashboardScreen(title: 'Dashboard'),
    };
  }
}
