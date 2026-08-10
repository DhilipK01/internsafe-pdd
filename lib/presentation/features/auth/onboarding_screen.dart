import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_brand.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingPage(
      icon: LucideIcons.alertTriangle,
      color: AppPalette.amber,
      title: 'Internship scams are rising',
      body:
          'Thousands of students lose money and personal data to fake offers. ${AppBrand.name} is your AI cyber shield.',
    ),
    _OnboardingPage(
      icon: LucideIcons.brainCircuit,
      color: AppPalette.neonMint,
      title: 'AI-powered protection',
      body:
          'Verify companies, scan offers, protect resumes, and access a global fraud intelligence network.',
    ),
    _OnboardingPage(
      icon: LucideIcons.rocket,
      color: AppPalette.cyberBlue,
      title: 'Secure every career step',
      body:
          'From first application to onboarding — know what to share, when, and what to never share.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(authRepositoryProvider).completeOnboarding();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                child: Center(child: InternsafeLogo(size: 48, showGlow: true)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: AppTypography.label(
                      color: context.accentColor,
                      dark: context.isDark,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _pages[i],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppPalette.neonMint
                          : context.borderColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: _page == i
                          ? [
                              BoxShadow(
                                color: AppPalette.neonMint.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: _page == _pages.length - 1 ? 'Get Started' : 'Next',
                  onPressed: () {
                    if (_page < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      _finish();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassSurface(
            accentColor: color,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Icon(icon, size: 64, color: color),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            title,
            style: AppTypography.displayMedium(dark: context.isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            body,
            style: AppTypography.onboardingSubtitle(dark: context.isDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
