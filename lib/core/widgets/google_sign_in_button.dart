import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SignInButton(
        Buttons.google,
        text: 'Continue with Google',
        onPressed: isLoading || onPressed == null ? () {} : onPressed!,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
