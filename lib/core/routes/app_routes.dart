import 'package:flutter/material.dart';
import '../../frontend/onboarding_page/onboarding_page.dart';
import '../../frontend/dashboard/dashboard_screen.dart';

class AppRoutes {
  AppRoutes._(); // Private constructor

  static const String root = '/'; // standalone backlash indicates landing page.
  static const String authGate = '/authGate';
  static const String onboardingPage = '/onboardingPage';
  static const String dashboard = '/dashboard';

  // Pass the simulatedToday in the parameters
  static Map<String, WidgetBuilder> define(
    ValueNotifier<DateTime> mockTodayNotifier,
  ) {
    return {
      // ROOT
      root: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardScreen(title: 'Dashboard', simulatedToday: date);
        },
      ),

      // ONBOARDING PAGE
      onboardingPage: (context) => OnboardingPage(),

      // DASHBOARD
      dashboard: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardScreen(title: 'Dashboard', simulatedToday: date);
        },
      ),
    };
  }
}
