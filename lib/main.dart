// Remember the Golden Rule: everything is a widget!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// CORE
import 'package:period_tracker/core/core.dart';

// FEATURES
import 'package:period_tracker/features/features.dart';

// APP ROUTE
import 'package:period_tracker/app_routes.dart';

// Global debug date (change this and hot reload)
final ValueNotifier<DateTime> mockToday = ValueNotifier(DateTime(2026, 4, 27));

// 1. The Ignition Point
void main() async {
  // 2.The Attachment
  // runApp() is only in main.dart
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core utilities
  await PrefsUtils.init();

  runApp(const PeriodTrackingApp());
}

// 3. MaterialApp: The Foundation
// StatelessWidget: The App's Blueprint / the Main Wrapper
class PeriodTrackingApp extends StatelessWidget {
  // Constructor
  const PeriodTrackingApp({super.key});

  // This widget is the root of your application.
  // Returns the a Widget Tree
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => DashboardViewModel()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.dashboard,
        routes: AppRoutes.define(mockToday),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      ),
    );
  }
}
