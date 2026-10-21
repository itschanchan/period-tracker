import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/login_screen.dart';
import 'package:period_tracker/register_screen.dart';
import 'package:period_tracker/features/dashboard/views/dashboard_view.dart';
import 'package:period_tracker/features/calendar/views/calendar_view.dart';
import 'package:period_tracker/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:period_tracker/frontend/onboarding_page/onboarding_page.dart';

class AppRoutes {
  AppRoutes._(); // Private constructor

  static const String root = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String register = '/register';
  static const String calendar = '/calendar';
  static const String onboardingPage = '/onboarding';

  static Map<String, WidgetBuilder> define(
    ValueNotifier<DateTime> mockTodayNotifier,
  ) {
    return {
      root: (context) => const LoginScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      onboardingPage: (context) => const OnboardingPage(),
      dashboard: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          return DashboardView(simulatedToday: date);
        },
      ),
      calendar: (context) => ValueListenableBuilder<DateTime>(
        valueListenable: mockTodayNotifier,
        builder: (context, date, _) {
          final dashboardViewModel = Provider.of<DashboardViewModel>(
            context,
            listen: false,
          );
          return CalendarView(dashboardViewModel: dashboardViewModel);
        },
      ),
    };
  }
}
