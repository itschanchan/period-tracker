// Notification Repository Implementation
// Location: lib/data/repositories/notification_repository_impl.dart

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:period_tracker/core/utils/notification_service.dart';
import 'repositories.dart';

/// Implementation of NotificationRepository using the existing NotificationService
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _notificationService = NotificationService();

  @override
  Future<void> initialize() async {
    // The NotificationService requires a context and viewModel for initialization
    // This is handled by the app startup in main.dart
    // We just expose the functionality here
  }

  @override
  Future<void> schedulePeriodReminder(DateTime date) async {
    // The NotificationService handles scheduling automatically
    // This method can be used for manual scheduling if needed
    _notificationService.checkNotifications();
  }

  @override
  Future<void> cancelPeriodReminder() async {
    // Not implemented in current NotificationService
    // Would require cancelling scheduled notifications
  }

  @override
  Future<bool> requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}