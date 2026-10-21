// Remember the Golden Rule: everything is a widget!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';

// CORE
import 'package:period_tracker/core/core.dart';
import 'package:period_tracker/core/routes/app_routes.dart';
import 'package:period_tracker/backend/firebase_options.dart';

// FEATURES
import 'package:period_tracker/features/features.dart';

// VIEW MODELS
import 'package:period_tracker/backend/viewModels/health_logs_view_model.dart';
import 'package:period_tracker/backend/viewModels/daily_monitor_view_model.dart';

// SERVICES
import 'package:period_tracker/backend/services/notification_service.dart';

// Global debug date (change this and hot reload)
final ValueNotifier<DateTime> mockToday = ValueNotifier(DateTime.now());

// Global navigator key for debugging context-related issues
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 1. The Ignition Point
void main() async {
  // 2.The Attachment
  // runApp() is only in main.dart
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core utilities (local persistence)
  await PrefsUtils.init();

  // Initialize the remote services in parallel to speed up startup.
  // Failures are non fatal: the app still runs on local data.
  try {
    await Future.wait([
      _initFirebase(),
      _initSupabase(),
    ]).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Startup services timed out or failed: $e');
  }

  runApp(const PeriodTrackingApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
}

Future<void> _initSupabase() async {
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }
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
        ChangeNotifierProvider(
          create: (context) {
            final vm = HealthLogsViewModel();
            vm.initializeData();
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final vm = DailyMonitorViewModel();
            vm.initializeData();
            return vm;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize the notification service once the providers are ready.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final dashboardViewModel = Provider.of<DashboardViewModel>(
                context,
                listen: false,
              );
              NotificationService().initialize(context, dashboardViewModel);
            } catch (e) {
              debugPrint('Notification service initialization failed: $e');
            }
          });

          return MaterialApp(
            title: AppConstants.appName,
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            initialRoute: AppRoutes.dashboard,
            routes: AppRoutes.define(mockToday),
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
          );
        },
      ),
    );
  }
}
