import 'package:flutter/foundation.dart';
import 'package:internsfe/core/auth/auth_session_manager.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/data/services/auth_token_storage.dart';
import 'package:internsfe/data/services/google_sign_in_service.dart';
import 'package:internsfe/domain/entities/user_profile.dart';
import 'package:internsfe/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._api,
    this._storage, {
    AuthSessionManager? sessionManager,
    GoogleSignInService? googleSignIn,
    void Function()? onSessionChanged,
  })  : _session = sessionManager ?? AuthSessionManager(_storage),
        _googleSignIn = googleSignIn ?? GoogleSignInService(),
        _onSessionChanged = onSessionChanged;

  final ApiClient _api;
  final AuthTokenStorage _storage;
  final AuthSessionManager _session;
  final GoogleSignInService _googleSignIn;
  final void Function()? _onSessionChanged;
  static const _onboardingKey = 'onboarding_done';

  Future<AuthResult> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserProfile.fromJson(userJson);
    await _session.applyLoginSession(token: token, user: user);
    _onSessionChanged?.call();
    if (kDebugMode) {
      debugPrint('[Auth] session persisted userId=${user.id} email=${user.email}');
    }
    return AuthResult(token: token, user: user);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final data = await _api.postJson('/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    return _persistSession(data);
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String name, {
    String? college,
  }) async {
    final data = await _api.postJson('/auth/register', body: {
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      if (college != null) 'college': college,
    });
    return _persistSession(data);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    final googleSignIn = _googleSignIn.create();
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in cancelled');
    }
    final auth = await account.authentication;
    final token = auth.idToken ?? auth.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Failed to obtain Google ID or Access token');
    }
    final data = await _api.postJson('/auth/google', body: {'idToken': token});
    return _persistSession(data);
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.getJson('/auth/me');
      final raw = data['user'];
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid /auth/me response');
      }
      return UserProfile.fromJson(_normalizeMeUser(raw));
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] getCurrentUser failed: $e');
      await _session.clearSession();
      _onSessionChanged?.call();
      return null;
    }
  }

  Map<String, dynamic> _normalizeMeUser(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'email': raw['email'],
      'name': raw['name'],
      'college': raw['college'] ?? raw['college_name'],
    };
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return false;
    return (await getCurrentUser()) != null;
  }

  @override
  Future<void> signOut() async {
    await _session.clearSession();
    _onSessionChanged?.call();
    if (kDebugMode) debugPrint('[Auth] signOut complete');
    try {
      await _googleSignIn.create().signOut();
    } catch (_) {}
  }

  @override
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  @override
  Future<String> requestPasswordResetOtp(String email) async {
    final data = await _api.postJson('/auth/forgot-password/request', body: {
      'email': email.trim(),
    });
    return data['requestId'] as String;
  }

  @override
  Future<String> resendPasswordResetOtp({
    required String email,
    required String requestId,
  }) async {
    final data = await _api.postJson('/auth/forgot-password/resend', body: {
      'email': email.trim(),
      'requestId': requestId,
    });
    return data['requestId'] as String? ?? requestId;
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String requestId,
    required String otp,
  }) async {
    final data = await _api.postJson('/auth/forgot-password/verify', body: {
      'email': email.trim(),
      'requestId': requestId,
      'otp': otp.trim(),
    });
    return data['resetToken'] as String;
  }

  @override
  Future<void> resetPasswordWithToken({
    required String resetToken,
    required String password,
    required String confirmPassword,
  }) async {
    await _api.postJson('/auth/forgot-password/reset', body: {
      'resetToken': resetToken,
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }
}
