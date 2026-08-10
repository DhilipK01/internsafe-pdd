import 'package:internsfe/domain/entities/user_profile.dart';

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserProfile user;
}

abstract class AuthRepository {
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String name, {
    String? college,
  });
  Future<AuthResult> signInWithGoogle();
  Future<UserProfile?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> signOut();
  Future<void> completeOnboarding();
  Future<bool> hasCompletedOnboarding();

  Future<String> requestPasswordResetOtp(String email);
  Future<String> resendPasswordResetOtp({
    required String email,
    required String requestId,
  });
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String requestId,
    required String otp,
  });
  Future<void> resetPasswordWithToken({
    required String resetToken,
    required String password,
    required String confirmPassword,
  });
}
