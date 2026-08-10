import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:internsfe/data/services/google_sign_in_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/auth_providers.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/constants/app_brand.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/google_sign_in_button.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignup = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).message;
    }
    return GoogleSignInService.mapError(e);
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password (6+ chars)')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignup) {
        if (_nameController.text.trim().isEmpty) {
          throw ApiException('Name is required');
        }
        await ref.read(authRepositoryProvider).signUpWithEmail(
              _emailController.text,
              _passwordController.text,
              _nameController.text,
            );
      } else {
        await ref.read(authRepositoryProvider).signInWithEmail(
              _emailController.text,
              _passwordController.text,
            );
      }
      if (mounted) {
        ref.invalidate(dashboardProvider);
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) {
        ref.invalidate(dashboardProvider);
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandMeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Center(child: InternsafeLogo(size: 80, animate: true))
                    .animate()
                    .fadeIn()
                    .scale(begin: const Offset(0.92, 0.92)),
                const SizedBox(height: AppSpacing.md),
                const Center(child: InternsafeBrandTitle(large: true)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _isSignup ? 'Create Account' : 'Welcome Back',
                  style: AppTypography.displayMedium(dark: context.isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Next-gen protection for your internship journey',
                  style: AppTypography.body(dark: context.isDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                GlassSurface(
                  child: Column(
                    children: [
                      if (_isSignup) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(LucideIcons.user),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(LucideIcons.mail),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(LucideIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? LucideIcons.eyeOff
                                  : LucideIcons.eye,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      if (!_isSignup)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.push(AppRoutes.forgotPassword),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: AppTypography.label(
                                color: context.accentColor,
                                dark: context.isDark,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryButton(
                        label: _isSignup ? 'Sign Up' : 'Log In',
                        onPressed: _isLoading ? null : _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      GoogleSignInButton(
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _googleSignIn,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignup ? 'Already have an account?' : 'New to ${AppBrand.name}?',
                      style: AppTypography.caption(dark: context.isDark),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSignup = !_isSignup),
                      child: Text(
                        _isSignup ? 'Log In' : 'Sign Up',
                        style: AppTypography.label(
                          color: context.accentColor,
                          dark: context.isDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push(AppRoutes.terms),
                      child: Text(
                        'Terms of Service',
                        style: AppTypography.caption(
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        color: context.borderColor,
                        fontSize: 10,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.privacy),
                      child: Text(
                        'Privacy Policy',
                        style: AppTypography.caption(
                          color: context.mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
