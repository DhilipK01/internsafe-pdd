import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:internsfe/core/config/env_config.dart';

/// Android Google Sign-In (package: `com.internsafe.internsfe`).
///
/// Requires in Google Cloud Console:
/// 1. OAuth client type **Android** — package + SHA-1 fingerprint(s)
/// 2. OAuth client type **Web** — its Client ID goes in `.env` as [EnvConfig.googleServerClientId]
class GoogleSignInService {
  GoogleSignIn create() {
    final serverClientId = EnvConfig.googleServerClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      throw StateError(
        'GOOGLE_WEB_CLIENT_ID (or GOOGLE_CLIENT_ID) is missing in .env. '
        'Use the Web application OAuth client ID, not the Android client ID.',
      );
    }
    return GoogleSignIn(
      clientId: kIsWeb ? serverClientId : null,
      scopes: const ['email', 'profile', 'openid'],
      serverClientId: serverClientId,
    );
  }

  static String mapError(Object error) {
    if (error is PlatformException) {
      final message = error.message ?? '';
      if (error.code == 'sign_in_failed' &&
          (message.contains('ApiException: 10') || message.contains(': 10:'))) {
        return 'Google Sign-In setup error (code 10). In Google Cloud Console, '
            'add an Android OAuth client for package com.internsafe.internsfe '
            'with your app SHA-1, and set GOOGLE_WEB_CLIENT_ID in .env to the '
            'Web application client ID (not the Android client ID).';
      }
      if (error.code == 'sign_in_failed') {
        return 'Google sign-in failed. Check OAuth configuration and try again.';
      }
    }
    if (error is StateError) return error.message;
    return error.toString();
  }
}
