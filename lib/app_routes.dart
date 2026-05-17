import 'package:flutter/material.dart';
import '/dashboard/dashboard_screen.dart';

class AppRoutes {
  AppRoutes._(); // Private constructor

  static const String root = '/'; // standalone backlash indicates landing page.
  static const String authGate = '/authGate';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String register = '/register';

  // Pass the simulatedToday in the parameters
  static Map<String, WidgetBuilder> define(
    ValueNotifier<DateTime> mockTodayNotifier,
  ) {
    return {
      root: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardScreen(title: 'Dashboard', simulatedToday: date);
        },
      ),
      dashboard: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardScreen(title: 'Dashboard', simulatedToday: date);
        },
      ),
    };
  }
}
