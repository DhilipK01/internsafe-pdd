import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/auth_providers.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/brand/app_motion.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_durations.dart';
import 'package:internsfe/core/routing/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(AppDurations.splash);
    if (!mounted) return;
    await ref.read(authSessionManagerProvider).restoreSession();
    final auth = ref.read(authRepositoryProvider);
    final onboardingDone = await auth.hasCompletedOnboarding();
    final loggedIn = await auth.isLoggedIn();
    if (loggedIn) {
      ref.read(authSessionGenerationProvider.notifier).state++;
    }
    if (!mounted) return;
    if (!onboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (loggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taglineColor = isDark
        ? AppPalette.neonMint.withValues(alpha: 0.92)
        : AppPalette.emeraldCore;

    return Scaffold(
      body: BrandMeshBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const InternsafeLogoReveal(size: 128),
              const SizedBox(height: 28),
              const InternsafeBrandTitle(large: true, showLogo: false, logoSize: 0)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: AppMotion.normal)
                  .slideY(begin: 0.15, end: 0, curve: AppMotion.easeOut),
              const SizedBox(height: 10),
              Text(
                'AI CYBER PROTECTION FOR STUDENTS',
                style: AppTypography.metricLabel(
                  color: taglineColor,
                  dark: isDark,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 56),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: taglineColor,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
