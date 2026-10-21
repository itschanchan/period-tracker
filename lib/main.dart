// Remember the Golden Rule: everything is a widget!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'backend/firebase_options.dart';

// APP ROUTE
import 'package:period_tracker/core/routes/app_routes.dart';

// VIEW MODELS
import 'package:period_tracker/backend/viewModels/cycle_view_model.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in parallel to speed up startup
  try {
    await Future.wait([
      Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).catchError((e) {
        debugPrint('Firebase initialization failed: $e');
        return null;
      }),
      Supabase.initialize(
        url: 'https://imksmtwlwrechduzdszp.supabase.co',
        anonKey: 'sb_publishable_pMDkbawnZS0vClTp4HfHNg_DF26vML2',
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      ).catchError((e) {
        debugPrint('Supabase initialization failed: $e');
      }),
    ]).timeout(
      const Duration(seconds: 10),
    ); // Prevent total hang if services are down
  } catch (e) {
    debugPrint('Startup services timed out or failed: $e');
  }

  // 2.The Attachment
  // runApp() is only in main.dart
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
    // 1. Define your mock date here.
    // Simply change this date and save (Hot Reload) to move "Today" in the app.
    // final DateTime mockToday = DateTime.now();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CycleViewModel()),
        ChangeNotifierProvider(
          create: (context) {
            final vm = HealthLogsViewModel();
            vm.initializeData();
            return vm;
          },
        ),
        ChangeNotifierProvider(create: (context) => DailyMonitorViewModel()),
      ],
      child: Builder(
        builder: (context) {
          // Initialize notification service after providers are set up
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              final cycleViewModel = Provider.of<CycleViewModel>(
                context,
                listen: false,
              );
              NotificationService().initialize(context, cycleViewModel);
            } catch (e) {
              debugPrint('Notification service initialization failed: $e');
            }
          });

          return MaterialApp(
            title: 'Period Tracker',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner:
                false, // removes the "DEBUG" tag on the top right corner of the screen.
            // 1. Set the starting screen
            initialRoute: AppRoutes.dashboard,
            // 2. Load the map from app_routes.dart file
            routes: AppRoutes.define(mockToday),
            // 3. Set the global theme
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
            ),
          );
        },
      ),
    );
  }
}

/*  
  NOTES:
  - Dart requires the class name for static methods and enums, unlike languages like Swift.
  - Why use Theme.of(context).platform?
  - Using the Theme approach is often better for UI logic because it allows you to test your 
    "Apple" layout on other platforms by simply overriding the ThemeData.platform in your MaterialApp. 
    If you strictly want to know the physical hardware platform, you can also use defaultTargetPlatform 
    after importing package:flutter/foundation.dart.
*/
