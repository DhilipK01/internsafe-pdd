import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/data/api/api_client.dart';
import 'package:internsfe/data/services/auth_token_storage.dart';

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(authTokenStorageProvider));
});
