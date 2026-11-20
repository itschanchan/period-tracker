// Repository Contracts
// Location: lib/data/repositories/repositories.dart

/// Authentication repository interface
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges;

  /// Sign in with email and password
  /// Returns authenticated user or throws AuthException
  Future<User?> signInWithEmail(String email, String password);

  /// Register new user with email and password
  /// Returns authenticated user or throws AuthException
  Future<User?> registerWithEmail(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Get currently authenticated user
  Future<User?> getCurrentUser();
}

/// Database repository interface for period tracking data
abstract class DatabaseRepository {
  /// Get daily logs for a user within date range
  Future<List<DailyLog>> getDailyLogs(String userId, DateTime start, DateTime end);

  /// Get daily log for specific date
  Future<DailyLog?> getDailyLog(String userId, DateTime date);

  /// Save or update daily log
  Future<void> saveDailyLog(DailyLog log);

  /// Delete daily log
  Future<void> deleteDailyLog(String userId, String logId);

  /// Get period days for a user within date range
  Future<List<PeriodDay>> getPeriodDays(String userId, DateTime start, DateTime end);
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

/// Authentication exceptions
sealed class AuthException implements Exception {
  const AuthException(this.details);
  final String details;

  factory AuthException.invalidCredentials() = _InvalidCredentials;
  factory AuthException.userNotFound() = _UserNotFound;
  factory AuthException.emailAlreadyInUse() = _EmailAlreadyInUse;
  factory AuthException.weakPassword() = _WeakPassword;
  factory AuthException.networkError(String details) = _NetworkError;
  factory AuthException.unknown(String details) = _Unknown;
}

class _InvalidCredentials extends AuthException {
  _InvalidCredentials() : super('Invalid email or password');
}

class _UserNotFound extends AuthException {
  _UserNotFound() : super('No user found with this email');
}

class _EmailAlreadyInUse extends AuthException {
  _EmailAlreadyInUse() : super('An account already exists with this email');
}

class _WeakPassword extends AuthException {
  _WeakPassword() : super('Password is too weak (minimum 6 characters)');
}

class _NetworkError extends AuthException {
  _NetworkError(super.details);
}

class _Unknown extends AuthException {
  _Unknown(super.details);
}

/// Contract model: User
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

/// Contract model: DailyLog
class DailyLog {
  final String id;
  final String userId;
  final DateTime date;
  final String? flow;
  final List<String> symptoms;
  final List<String> moods;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyLog({
    required this.id,
    required this.userId,
    required this.date,
    this.flow,
    this.symptoms = const [],
    this.moods = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Contract model: PeriodDay
class PeriodDay {
  final String id;
  final String userId;
  final DateTime date;
  final String flow;
  final bool isPeriodStart;
  final bool isPeriodEnd;

  const PeriodDay({
    required this.id,
    required this.userId,
    required this.date,
    required this.flow,
    this.isPeriodStart = false,
    this.isPeriodEnd = false,
  });
}

/// Contract model: OnboardItem
class OnboardItem {
  final String id;
  final String title;
  final String description;
  final String? imageAsset;
  final int order;

  const OnboardItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageAsset,
    required this.order,
  });
}