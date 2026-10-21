import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:period_tracker/frontend/notification/notification_detail_screen.dart';
import 'package:period_tracker/backend/viewModels/cycle_view_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:period_tracker/backend/services/database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _dbService = DatabaseService();
  CycleViewModel? _CycleViewModel;
  BuildContext? _context;
  String? _fcmToken;

  void initialize(BuildContext context, CycleViewModel CycleViewModel) async {
    _context = context;
    _CycleViewModel = CycleViewModel;

    await _initializeLocalNotifications();
    _setupFirebaseMessaging();
    _scheduleDailyNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings, // Use iOS settings for macOS as well
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (_context == null) return;

    // Navigate to notification detail screen
    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          title: response.payload?.split('|')[0] ?? 'Notification',
          body: response.payload?.split('|')[1] ?? 'No details available',
        ),
      ),
    );
  }

  void _setupFirebaseMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token (vapidKey is required for Web)
    _fcmToken = await _messaging.getToken(
      vapidKey:
          "BKuih-r3cgrc93IHsLhChqgAmCQ_KbiOXvDrZmcF5ESOdVlpFuqfGAhk7G_QPSJ9tOOkbWkjkIi86tAOnpJOXFU", // Paste your key from Firebase Console here
    );
    print("FCM Token: $_fcmToken");

    if (_fcmToken != null) {
      await _dbService.updateFcmToken(_fcmToken!);
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle background notifications when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleBackgroundMessage(message);
    });

    // Handle terminated state notifications
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleTerminatedMessage(message);
      }
    });

    // Listen for token updates
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint("FCM Token updated: $newToken");
      _dbService.updateFcmToken(newToken);
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          body,
          maxLines: 1,
          style: TextStyle(overflow: TextOverflow.ellipsis),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotificationDetailScreen(title: title, body: body),
                ),
              );
            },
            child: Text("Next"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(title: title, body: body),
      ),
    );
  }

  void _handleTerminatedMessage(RemoteMessage message) {
    if (_context == null) return;

    final title = message.notification?.title ?? "N/A";
    final body = message.notification?.body ?? "N/A";

    Navigator.push(
      _context!,
      MaterialPageRoute(
        builder: (context) =>
            NotificationDetailScreen(title: title, body: body),
      ),
    );
  }

  void _scheduleDailyNotifications() {
    // Check for notifications when app starts
    _checkAndSendNotifications();

    // Schedule daily checks at midnight
    _scheduleNextDayCheck();
  }

  void _scheduleNextDayCheck() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final midnight = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      0,
      0,
      0,
    );

    final duration = midnight.difference(now);

    Future.delayed(duration, () {
      _checkAndSendNotifications();
      _scheduleNextDayCheck(); // Schedule the next check
    });
  }

  /// Get the FCM token for this device (useful for backend integration)
  String? get fcmToken => _fcmToken;

  void _checkAndSendNotifications() {
    if (_CycleViewModel == null) return;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // 7-day pre-period countdown check.
    // Returns true if a countdown notification was sent, so we can
    // skip the generic period reminder and avoid double notifications.
    final sentCountdown = _checkPrePeriodCountdown(todayOnly);

    // Check if today is in predicted period (skip if countdown already covered it)
    if (!sentCountdown && _isTodayInPredictedPeriod(todayOnly)) {
      _sendNotification(
        title: "Period Reminder",
        body:
            "Today is your predicted period day. Have you started your period?",
        notificationType: "period_reminder",
      );
    }

    // Check if today is in fertile window
    if (_isTodayInFertileWindow(todayOnly)) {
      _sendNotification(
        title: "Fertile Window",
        body: "Today is in your fertile window. Track your symptoms!",
        notificationType: "fertile_window",
      );
    }

    // Check if today is ovulation day
    if (_isTodayOvulationDay(todayOnly)) {
      _sendNotification(
        title: "Ovulation Day",
        body: "Today is your ovulation day!",
        notificationType: "ovulation_day",
      );
    }
  }

  bool _isTodayInPredictedPeriod(DateTime today) {
    if (_CycleViewModel == null) return false;

    final nextPeriodDate = _CycleViewModel!.nextPeriodDate;
    final mensesLength = _CycleViewModel!.mensesLength;

    for (int i = 0; i < mensesLength; i++) {
      final periodDay = nextPeriodDate.add(Duration(days: i));
      final periodDayOnly = DateTime(
        periodDay.year,
        periodDay.month,
        periodDay.day,
      );

      if (periodDayOnly.isAtSameMomentAs(today)) {
        return true;
      }
    }
    return false;
  }

  bool _isTodayInFertileWindow(DateTime today) {
    if (_CycleViewModel == null) return false;

    final fertileStart = _CycleViewModel!.fertileWindowStart;
    final fertileEnd = _CycleViewModel!.fertileWindowEnd;

    final fertileStartOnly = DateTime(
      fertileStart.year,
      fertileStart.month,
      fertileStart.day,
    );
    final fertileEndOnly = DateTime(
      fertileEnd.year,
      fertileEnd.month,
      fertileEnd.day,
    );

    return today.isAtSameMomentAs(fertileStartOnly) ||
        today.isAtSameMomentAs(fertileEndOnly) ||
        (today.isAfter(fertileStartOnly) && today.isBefore(fertileEndOnly));
  }

  bool _isTodayOvulationDay(DateTime today) {
    if (_CycleViewModel == null) return false;

    final ovulationDate = _CycleViewModel!.ovulationDate;
    final ovulationOnly = DateTime(
      ovulationDate.year,
      ovulationDate.month,
      ovulationDate.day,
    );

    return today.isAtSameMomentAs(ovulationOnly);
  }

  /// Checks if today falls within the 7-day window before the next predicted
  /// period and sends the appropriate countdown or period-overlap notification.
  /// Returns `true` if a notification was sent (used for deduplication).
  bool _checkPrePeriodCountdown(DateTime today) {
    if (_CycleViewModel == null) return false;

    final nextPeriod = _CycleViewModel!.nextPeriodDate;
    final nextPeriodOnly = DateTime(
      nextPeriod.year,
      nextPeriod.month,
      nextPeriod.day,
    );

    final daysUntilPeriod = nextPeriodOnly.difference(today).inDays;

    // Only act within the 7-day countdown window (1–7 days before).
    if (daysUntilPeriod < 1 || daysUntilPeriod > 7) return false;

    // If today is also a predicted period day (overlap with current cycle),
    // send the special "mark it down" message instead of a countdown.
    if (_CycleViewModel!.isPredictedPeriodDay(today)) {
      _sendNotification(
        title: "Period Check-In 📋",
        body:
            "Hello user! Are you on your period today? Mark it down the calendar now.",
        notificationType: "pre_period_overlap",
      );
      return true;
    }

    // Build the countdown message.
    final String body;
    if (daysUntilPeriod == 1) {
      body = "Your period starts tomorrow! Get ready! 🌸";
    } else {
      body = "Your period is expected in $daysUntilPeriod days. Get ready! 🌸";
    }

    _sendNotification(
      title: "Period Countdown ⏳",
      body: body,
      notificationType: "pre_period_countdown",
    );
    return true;
  }

  /// Send notification via FCM (for server-triggered notifications)
  /// Also sends local notification for immediate testing
  void _sendNotification({
    required String title,
    required String body,
    String notificationType = "period_reminder",
  }) async {
    // Send local notification (works when app is closed)
    await _sendLocalNotification(title: title, body: body);

    // FCM message structure for backend implementation
    if (_fcmToken != null) {
      final message = {
        "to": _fcmToken,
        "notification": {"title": title, "body": body},
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "notification_type": notificationType,
        },
      };

      print("FCM Message ready for backend: $message");
      // TODO: Send this to your backend API for server-triggered notifications
    }
  }

  Future<void> _sendLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'period_tracker_channel',
          'Period Tracker Notifications',
          channelDescription: 'Notifications for period tracking reminders',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
      payload: '$title|$body',
    );
  }

  // Method to manually trigger notification check (useful for testing)
  void checkNotifications() {
    _checkAndSendNotifications();
  }
}
