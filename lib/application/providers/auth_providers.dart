import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/app_providers.dart';
import 'package:internsfe/core/auth/auth_session_manager.dart';
import 'package:internsfe/data/repositories/api_auth_repository.dart';
import 'package:internsfe/domain/entities/user_profile.dart';
import 'package:internsfe/domain/repositories/auth_repository.dart';

/// Bumped on every login/logout so dependent providers refetch the active user.
final authSessionGenerationProvider = StateProvider<int>((ref) => 0);

final authSessionManagerProvider = Provider<AuthSessionManager>((ref) {
  return AuthSessionManager(ref.watch(authTokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final session = ref.watch(authSessionManagerProvider);
  return ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authTokenStorageProvider),
    sessionManager: session,
    onSessionChanged: () {
      ref.read(authSessionGenerationProvider.notifier).state++;
    },
  );
});

/// Fetches the authenticated user from `GET /auth/me` whenever the session changes.
final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authSessionGenerationProvider);
  final session = ref.read(authSessionManagerProvider);
  await session.restoreSession();

  if (!await session.hasActiveSession()) {
    session.logProfileFetch(user: null);
    return null;
  }

  try {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    session.logProfileFetch(user: user);
    return user;
  } catch (e, st) {
    session.logProfileFetch(error: e);
    if (kDebugMode) debugPrint('[CurrentUser] $st');
    rethrow;
  }
});

void refreshAuthSession(WidgetRef ref) {
  ref.read(authSessionGenerationProvider.notifier).state++;
  ref.invalidate(currentUserProvider);
}
