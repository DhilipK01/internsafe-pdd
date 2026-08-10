import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/dialogs/confirmation_dialog_service.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/utils/password_validator.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum _ForgotStep { email, otp, reset, success }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _ForgotStep _step = _ForgotStep.email;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());

  String? _requestId;
  String? _resetToken;
  bool _loading = false;
  String _loadingMessage = '';
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    return e.toString();
  }

  void _startResendCooldown([int seconds = 59]) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _snack('Enter a valid email address.');
      return;
    }
    setState(() {
      _loading = true;
      _loadingMessage = 'Sending secure verification code...';
    });
    try {
      final id =
          await ref.read(authRepositoryProvider).requestPasswordResetOtp(email);
      setState(() {
        _requestId = id;
        _step = _ForgotStep.otp;
      });
      _startResendCooldown();
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_requestId == null || _resendSeconds > 0) return;
    setState(() {
      _loading = true;
      _loadingMessage = 'Sending secure verification code...';
    });
    try {
      final newId = await ref.read(authRepositoryProvider).resendPasswordResetOtp(
            email: _emailController.text.trim(),
            requestId: _requestId!,
          );
      setState(() => _requestId = newId);
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocus[0].requestFocus();
      _startResendCooldown();
      _snack('A new code was sent to your email.');
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _otpCode =>
      _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _snack('Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _loading = true;
      _loadingMessage = 'Verifying OTP...';
    });
    try {
      final token = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetOtp(
            email: _emailController.text.trim(),
            requestId: _requestId!,
            otp: _otpCode,
          );
      setState(() {
        _resetToken = token;
        _step = _ForgotStep.reset;
      });
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final validation = PasswordValidation.evaluate(_passwordController.text);
    if (!validation.isValid) {
      _snack('Password does not meet all requirements.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _snack('Passwords do not match.');
      return;
    }

    final confirmed = await ConfirmationDialogService.show(
      context,
      request: const ConfirmationRequest(
        title: 'Reset Password?',
        message:
            'Your new password will replace the current one. '
            'You will need to sign in again on other devices.',
        severity: ConfirmationSeverity.warning,
        icon: LucideIcons.keyRound,
        confirmLabel: 'Reset Password',
      ),
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _loading = true;
      _loadingMessage = 'Updating password securely...';
    });
    try {
      await ref.read(authRepositoryProvider).resetPasswordWithToken(
            resetToken: _resetToken!,
            password: _passwordController.text,
            confirmPassword: _confirmController.text,
          );
      if (mounted) {
        ConfirmationDialogService.showSuccessSnackBar(
          context,
          'Password updated successfully.',
        );
        setState(() => _step = _ForgotStep.success);
      }
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocus[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
    }
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        leading: _step == _ForgotStep.success
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_step == _ForgotStep.email) {
                    context.pop();
                  } else if (_step == _ForgotStep.otp) {
                    setState(() => _step = _ForgotStep.email);
                  } else {
                    setState(() => _step = _ForgotStep.otp);
                  }
                },
              ),
      ),
      body: BrandMeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: InternsafeBrandTitle()),
                const SizedBox(height: AppSpacing.lg),
                if (_loading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _loadingMessage,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.accentColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                GlassSurface(child: _buildStepContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    return switch (_step) {
      _ForgotStep.email => _buildEmailStep(context),
      _ForgotStep.otp => _buildOtpStep(context),
      _ForgotStep.reset => _buildResetStep(context),
      _ForgotStep.success => _buildSuccessStep(context),
    };
  }

  Widget _buildEmailStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot your password?',
          style: AppTypography.displayMedium(dark: context.isDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter your registered email. We will send a secure 6-digit verification code.',
          style: AppTypography.body(dark: context.isDark),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(LucideIcons.mail),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Send OTP',
          icon: LucideIcons.send,
          isLoading: _loading,
          onPressed: _loading ? null : _sendOtp,
        ),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your email',
          style: AppTypography.displayMedium(dark: context.isDark),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Enter the 6-digit code sent to ${_emailController.text.trim()}',
          style: AppTypography.body(dark: context.isDark),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 44,
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocus[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: ''),
                onChanged: (v) {
                  if (v.length > 1) {
                    _otpControllers[i].text = v.substring(v.length - 1);
                    _otpControllers[i].selection =
                        const TextSelection.collapsed(offset: 1);
                  }
                  _onOtpChanged(i, _otpControllers[i].text);
                },
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Verify OTP',
          isLoading: _loading,
          onPressed: _loading ? null : _verifyOtp,
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _resendSeconds > 0 || _loading ? null : _resendOtp,
          child: Text(
            _resendSeconds > 0
                ? 'Resend OTP in ${_resendSeconds}s'
                : 'Resend OTP',
          ),
        ),
      ],
    );
  }

  Widget _buildResetStep(BuildContext context) {
    final validation = PasswordValidation.evaluate(_passwordController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create new password',
          style: AppTypography.displayMedium(dark: context.isDark),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _passwordController,
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(LucideIcons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._passwordCheckTiles(validation),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: const Icon(LucideIcons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Update password',
          isLoading: _loading,
          onPressed: _loading ? null : _resetPassword,
        ),
      ],
    );
  }

  List<Widget> _passwordCheckTiles(PasswordValidation v) {
    final labels = {
      'minLength': 'At least 8 characters',
      'uppercase': 'Contains uppercase letter',
      'lowercase': 'Contains lowercase letter',
      'number': 'Contains a number',
      'special': 'Contains a special character',
    };
    return labels.entries.map((e) {
      final ok = v.checks[e.key] ?? false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: ok ? context.accentColor : context.mutedColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.value,
                style: context.textTheme.bodySmall?.copyWith(
                  color: ok ? context.accentColor : context.mutedColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSuccessStep(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 72, color: context.accentColor),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Password updated successfully',
          style: AppTypography.displayMedium(dark: context.isDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your INTERNSAFE AI account password has been securely updated. '
          'Please sign in with your new password.',
          style: AppTypography.body(dark: context.isDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Back to Login',
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
