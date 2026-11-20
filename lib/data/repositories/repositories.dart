// Repository Contracts
// Location: lib/data/repositories/repositories.dart

export 'auth_repository_impl.dart';
export 'database_repository_impl.dart';
export 'notification_repository_impl.dart';

import 'package:period_tracker/features/dashboard/models/daily_log.dart';
import 'package:period_tracker/features/calendar/models/period_day.dart';
import 'package:period_tracker/data/models/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;

  /// Sign in with email and password
  /// Returns authenticated user or throws RepositoryAuthException
  Future<UserModel?> signInWithEmail(String email, String password);

  /// Register new user with email and password
  /// Returns authenticated user or throws RepositoryAuthException
  Future<UserModel?> registerWithEmail(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get currently authenticated user
  Future<UserModel?> getCurrentUser();

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle();
}

/// Database repository interface for period tracking data
abstract class DatabaseRepository {
  /// Get daily logs for a user within date range
  Future<List<DailyLogModel>> getDailyLogs(String userId, DateTime start, DateTime end);

  /// Get daily log for specific date
  Future<DailyLogModel?> getDailyLog(String userId, DateTime date);

  /// Save or update daily log
  Future<void> saveDailyLog(DailyLogModel log);

  /// Delete daily log
  Future<void> deleteDailyLog(String userId, String logId);

  /// Get period days for a user within date range
  Future<List<PeriodDayModel>> getPeriodDays(String userId, DateTime start, DateTime end);

  /// Sync full data to cloud
  Future<void> syncFullData(
    String userId, {
    required int cycleLength,
    required int mensesLength,
    required List<DateTime> periodDates,
    required Map<DateTime, double> flowLogs,
    required Map<DateTime, int> painLogs,
    required Map<DateTime, Set<String>> symptomsLog,
    required Map<DateTime, Set<String>> activitiesLog,
  });

  /// Fetch period dates from cloud
  Future<List<DateTime>> fetchPeriodDates();
}

/// Notification repository interface
abstract class NotificationRepository {
  /// Initialize notification service (request permissions, setup channels)
  Future<void> initialize();

  /// Schedule period reminder notification
  Future<void> schedulePeriodReminder(DateTime date);

  /// Cancel scheduled period reminder
  Future<void> cancelPeriodReminder();

  /// Request notification permissions from user
  Future<bool> requestPermissions();
}

/// Repository authentication exceptions (renamed to avoid conflict with Supabase AuthException)
sealed class RepositoryAuthException implements Exception {
  const RepositoryAuthException(this.message);
  final String message;

  factory RepositoryAuthException.invalidCredentials() = _InvalidCredentials;
  factory RepositoryAuthException.userNotFound() = _UserNotFound;
  factory RepositoryAuthException.emailAlreadyInUse() = _EmailAlreadyInUse;
  factory RepositoryAuthException.weakPassword() = _WeakPassword;
  factory RepositoryAuthException.networkError(String details) = _NetworkError;
  factory RepositoryAuthException.unknown(String details) = _Unknown;
}

class _InvalidCredentials extends RepositoryAuthException {
  _InvalidCredentials() : super('Invalid email or password');
}

class _UserNotFound extends RepositoryAuthException {
  _UserNotFound() : super('No user found with this email');
}

class _EmailAlreadyInUse extends RepositoryAuthException {
  _EmailAlreadyInUse() : super('An account already exists with this email');
}

class _WeakPassword extends RepositoryAuthException {
  _WeakPassword() : super('Password is too weak (minimum 6 characters)');
}

class _NetworkError extends RepositoryAuthException {
  _NetworkError(super.details);
}

class _Unknown extends RepositoryAuthException {
  _Unknown(super.details);
}