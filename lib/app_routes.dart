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

  // Pass the simulatedToday in the parameters
  static Map<String, WidgetBuilder> define(
    ValueNotifier<DateTime> mockTodayNotifier,
  ) {
    return {
      root: (context) => const LoginScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      dashboard: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardScreen(title: 'Dashboard', simulatedToday: date);
        },
      ),
    };
  }
}
