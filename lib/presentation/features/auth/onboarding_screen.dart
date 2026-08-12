import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/app_typography.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_brand.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/layout/responsive_layout.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _mobilePageController = PageController();
  final _webPageController = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingPageData(
      stepNumber: '01',
      stepTag: 'THE PROBLEM',
      icon: LucideIcons.alertTriangle,
      color: AppPalette.amber,
      title: 'Internship scams are rising',
      subtitle: 'Identify Fraud Before You Apply',
      body:
          'Thousands of students lose money and personal data to fake offers every month. ${AppBrand.name} acts as your intelligent cyber shield to detect red flags instantly.',
      bullets: [
        'Fake offer letters demanding upfront training fees',
        'Phishing schemes stealing government ID & bank credentials',
        'Ghost companies recruiting through unverified channels',
      ],
    ),
    _OnboardingPageData(
      stepNumber: '02',
      stepTag: 'OUR SOLUTION',
      icon: LucideIcons.brainCircuit,
      color: AppPalette.neonMint,
      title: 'AI-powered protection',
      subtitle: 'Real-Time Fraud Verification Engine',
      body:
          'Verify companies, scan offer letters, inspect resumes for privacy leaks, and check our global community blacklist database in seconds.',
      bullets: [
        'Instant AI document & offer letter verification',
        'Global blacklisted recruiters & domain registry',
        'Resume PII masking & privacy leak detection',
      ],
    ),
    _OnboardingPageData(
      stepNumber: '03',
      stepTag: 'YOUR FUTURE',
      icon: LucideIcons.rocket,
      color: AppPalette.cyberBlue,
      title: 'Secure every career step',
      subtitle: 'End-to-End Internship Safety Assurance',
      body:
          'From your first application to your official offer letter — know what to share, when to share it, and what red flags to avoid at all costs.',
      bullets: [
        'Complete protection checklist for all applicants',
        'Community-verified reviews & blacklist reports',
        '100% confidential & free student cyber shield',
      ],
    ),
  ];

  Future<void> _finish() async {
    await ref.read(authRepositoryProvider).completeOnboarding();
    if (mounted) context.go(AppRoutes.login);
  }

  void _nextPage() {
    if (_page < _pages.length - 1) {
      final target = _page + 1;
      if (ResponsiveLayout.isDesktopWeb(context)) {
        _webPageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _mobilePageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (_page > 0) {
      final target = _page - 1;
      if (ResponsiveLayout.isDesktopWeb(context)) {
        _webPageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _mobilePageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _goToPage(int index) {
    if (ResponsiveLayout.isDesktopWeb(context)) {
      _webPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _mobilePageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _mobilePageController.dispose();
    _webPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktopWeb(context)) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mobile Layout (3 screens in a horizontal PageView — unchanged)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
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
                  controller: _mobilePageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _MobileOnboardingPage(data: _pages[i]),
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
                  onPressed: _nextPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Desktop Web Layout (3 distinct desktop screens with PageView navigation)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: BrandMeshBackground(
        child: Column(
          children: [
            // ── Top Header Bar with Step Navigation Tabs ──────────────────────
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                color: isDark
                    ? AppPalette.navyDeep.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppPalette.slateBorder.withValues(alpha: 0.4)
                        : AppPalette.mist.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const InternsafeBrandTitle(logoSize: 32),

                  const Spacer(),

                  // 3 Interactive Desktop Step Tabs
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final item = _pages[i];
                      final isSelected = _page == i;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: InkWell(
                          onTap: () => _goToPage(i),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? item.color.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? item.color.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? item.color
                                        : (isDark
                                            ? AppPalette.navyElevated
                                            : AppPalette.mist),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.black
                                            : (isDark
                                                ? AppPalette.textSecondaryDark
                                                : AppPalette.textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  item.stepTag,
                                  style: AppTypography.label(
                                    color: isSelected
                                        ? (isDark
                                            ? Colors.white
                                            : AppPalette.textPrimaryLight)
                                        : (isDark
                                            ? AppPalette.textSecondaryDark
                                            : AppPalette.textSecondaryLight),
                                    dark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Skip to Login Button
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip to Login',
                      style: AppTypography.labelMedium(
                        color: context.accentColor,
                        dark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main PageView Workspace (3 distinct desktop step screens) ──
            Expanded(
              child: PageView.builder(
                controller: _webPageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  return _WebStepScreen(
                    data: _pages[i],
                    isDark: isDark,
                  );
                },
              ),
            ),

            // ── Bottom Web Navigation Bar ────────────────────────────────────
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                color: isDark
                    ? AppPalette.navyDeep.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppPalette.slateBorder.withValues(alpha: 0.4)
                        : AppPalette.mist.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_page > 0)
                    OutlinedButton.icon(
                      onPressed: _prevPage,
                      icon: const Icon(LucideIcons.chevronLeft, size: 18),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 90),

                  const Spacer(),

                  // Step indicators (dots)
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => InkWell(
                        onTap: () => _goToPage(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: _page == i ? 36 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _page == i
                                ? _pages[_page].color
                                : context.borderColor,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: _page == i
                                ? [
                                    BoxShadow(
                                      color: _pages[_page]
                                          .color
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Next / Get Started button
                  SizedBox(
                    width: 180,
                    child: PrimaryButton(
                      label: _page == _pages.length - 1
                          ? 'Get Started'
                          : 'Next Step',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Model for Onboarding Steps
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.stepNumber,
    required this.stepTag,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bullets,
  });

  final String stepNumber;
  final String stepTag;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String body;
  final List<String> bullets;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Onboarding Page
// ─────────────────────────────────────────────────────────────────────────────
class _MobileOnboardingPage extends StatelessWidget {
  const _MobileOnboardingPage({required this.data});
  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassSurface(
            accentColor: data.color,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Icon(data.icon, size: 64, color: data.color),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            data.title,
            style: AppTypography.displayMedium(dark: context.isDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.body,
            style: AppTypography.onboardingSubtitle(dark: context.isDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Step Screen — Full Desktop Screen for each step (Step 1, Step 2, Step 3)
// ─────────────────────────────────────────────────────────────────────────────
class _WebStepScreen extends StatelessWidget {
  const _WebStepScreen({
    required this.data,
    required this.isDark,
  });

  final _OnboardingPageData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ResponsiveLayout.contentMaxWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left text & feature details (50%)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Step tag badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: data.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'STEP ${data.stepNumber} • ${data.stepTag}',
                        style: AppTypography.metricLabel(
                          color: data.color,
                          dark: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Main Title
                    Text(
                      data.title,
                      style: AppTypography.displayLarge(dark: isDark),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Subtitle
                    Text(
                      data.subtitle,
                      style: AppTypography.titleMedium(
                        color: data.color,
                        dark: isDark,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Description body
                    Text(
                      data.body,
                      style: AppTypography.body(dark: isDark).copyWith(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Bullet points
                    ...data.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: data.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.check,
                                size: 14,
                                color: data.color,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                b,
                                style: AppTypography.labelLarge(dark: isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 64),

              // Right Hero Card / Visual graphic panel (50%)
              Expanded(
                flex: 5,
                child: Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppPalette.navySurface.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.heroRadius),
                    border: Border.all(
                      color: data.color.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Ambient background glow
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: data.color.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      data.color.withValues(alpha: 0.3),
                                      data.color.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: data.color.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  data.icon,
                                  size: 72,
                                  color: data.color,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                '${AppBrand.name} Security Layer',
                                style: AppTypography.titleMedium(dark: isDark),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Step ${data.stepNumber} of 03',
                                style: AppTypography.caption(
                                  color: context.mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
