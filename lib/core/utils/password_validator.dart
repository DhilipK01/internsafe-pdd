class PasswordValidation {
  const PasswordValidation({
    required this.isValid,
    required this.checks,
  });

  final bool isValid;
  final Map<String, bool> checks;

  static PasswordValidation evaluate(String password) {
    final checks = {
      'minLength': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'number': RegExp(r'[0-9]').hasMatch(password),
      'special': RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    };
    return PasswordValidation(
      isValid: checks.values.every((v) => v),
      checks: checks,
    );
  }
}
