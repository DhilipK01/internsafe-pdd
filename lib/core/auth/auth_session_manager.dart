import 'package:flutter/foundation.dart';
import 'package:internsfe/data/services/auth_token_storage.dart';
import 'package:internsfe/domain/entities/user_profile.dart';

/// Single source of truth for the active auth session (token + user id).
class AuthSessionManager {
  AuthSessionManager(this._storage);

  final AuthTokenStorage _storage;

  Future<void> applyLoginSession({
    required String token,
    required UserProfile user,
  }) async {
    await _storage.saveSession(token: token, userId: user.id);
    _log('login', userId: user.id, email: user.email);
  }

  Future<void> clearSession() async {
    await _storage.clearSession();
    _log('logout');
  }

  Future<String?> readUserId() => _storage.readUserId();

  Future<String?> readToken() => _storage.readToken();

  Future<bool> hasActiveSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> restoreSession() async {
    final token = await readToken();
    final userId = await readUserId();
    _log(
      'restore',
      userId: userId,
      hasToken: token != null && token.isNotEmpty,
    );
  }

  void _log(
    String event, {
    String? userId,
    String? email,
    bool? hasToken,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[AuthSession] $event '
      'userId=${userId ?? "—"} '
      'email=${email ?? "—"} '
      'hasToken=${hasToken ?? "—"}',
    );
  }

  void logProfileFetch({UserProfile? user, Object? error}) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('[AuthSession] profile_fetch error=$error');
      return;
    }
    debugPrint(
      '[AuthSession] profile_fetch '
      'userId=${user?.id ?? "null"} email=${user?.email ?? "—"}',
    );
  }
}
