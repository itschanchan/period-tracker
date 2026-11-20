// Auth Repository Implementation
// Location: lib/data/repositories/auth_repository_impl.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:url_launcher/url_launcher.dart';

import 'package:period_tracker/data/models/user.dart';
import 'repositories.dart';

/// Supabase implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  /// Resolved lazily so the service can be constructed before (or without)
  /// Supabase being initialised.
  supabase.SupabaseClient get _supabase => supabase.Supabase.instance.client;

  @override
  Stream<UserModel?> get authStateChanges {
    try {
      return _supabase.auth.onAuthStateChange.map((state) {
        final user = state.session?.user;
        if (user == null) return null;
        return UserModel(
          id: user.id,
          email: user.email,
          displayName: user.userMetadata?['full_name'] as String?,
          photoURL: user.userMetadata?['avatar_url'] as String?,
          createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      });
    } catch (_) {
      return const Stream<UserModel?>.empty();
    }
  }

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw RepositoryAuthException.invalidCredentials();
      }
      return UserModel(
        id: user.id,
        email: user.email,
        displayName: user.userMetadata?['full_name'] as String?,
        photoURL: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } on RepositoryAuthException {
      rethrow;
    } on supabase.AuthApiException catch (e) {
      if (e.code == 'invalid_credentials') {
        throw RepositoryAuthException.invalidCredentials();
      }
      throw RepositoryAuthException.unknown(e.message);
    } catch (e) {
      throw RepositoryAuthException.networkError(e.toString());
    }
  }

  @override
  Future<UserModel?> registerWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw RepositoryAuthException.unknown('Registration failed');
      }
      return UserModel(
        id: user.id,
        email: user.email,
        displayName: user.userMetadata?['full_name'] as String?,
        photoURL: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } on RepositoryAuthException {
      rethrow;
    } on supabase.AuthApiException catch (e) {
      if (e.code == 'email_already_exists' || e.code == 'user_already_exists') {
        throw RepositoryAuthException.emailAlreadyInUse();
      }
      if (e.code == 'weak_password') {
        throw RepositoryAuthException.weakPassword();
      }
      throw RepositoryAuthException.unknown(e.message);
    } catch (e) {
      throw RepositoryAuthException.networkError(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      return UserModel(
        id: user.id,
        email: user.email,
        displayName: user.userMetadata?['full_name'] as String?,
        photoURL: user.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final res = await _supabase.auth.getOAuthSignInUrl(
          provider: supabase.OAuthProvider.google,
          redirectTo: Uri.base.origin,
          queryParams: {'prompt': 'select_account'},
        );
        final url = Uri.parse(res.url);
        await launchUrl(url, webOnlyWindowName: '_blank');
      } else {
        await _supabase.auth.signInWithOAuth(
          supabase.OAuthProvider.google,
          redirectTo: 'io.supabase.periodtracker://login-callback',
          queryParams: {'prompt': 'select_account'},
        );
      }
    } on RepositoryAuthException {
      rethrow;
    } catch (e) {
      throw RepositoryAuthException.networkError(e.toString());
    }
  }
}