import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStorage {
  AuthTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<void> saveSession({required String token, required String userId}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  @Deprecated('Use clearSession')
  Future<void> clearToken() => clearSession();
}
