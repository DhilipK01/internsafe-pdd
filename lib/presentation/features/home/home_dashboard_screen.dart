import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/layout/responsive_layout.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/empty_state.dart';
import 'package:internsfe/core/widgets/feature_tile.dart';
import 'package:internsfe/core/widgets/report_card.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/core/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return AppScaffold(
      title: 'Home',
      showBottomNav: true,
      bottomNavIndex: 0,
      padding: false,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.history),
          icon: Icon(LucideIcons.history, color: context.mutedColor),
          tooltip: 'History',
        ),
      ],
      body: BrandMeshBackground(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            title: 'Could not load dashboard',
            message: e.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) {
            if (ResponsiveLayout.isDesktopWeb(context)) {
              return _WebDashboardBody(data: data);
            }
            return _MobileDashboardBody(data: data);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Dashboard (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────
class _MobileDashboardBody extends StatelessWidget {
  const _MobileDashboardBody({required this.data});
  final dynamic data;

  IconData _iconForType(String type) => switch (type) {
        'resume' => LucideIcons.fileText,
        'offer' => LucideIcons.fileWarning,
        'company' => LucideIcons.building2,
        _ => LucideIcons.ban,
      };

  Color _colorForType(String type) => switch (type) {
        'resume' => AppPalette.cyberBlue,
        'offer' => AppPalette.crimson,
        'company' => AppPalette.emeraldBright,
        _ => AppPalette.amber,
      };

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${data.user.name}',
                      style: context.textTheme.headlineMedium,
                    ),
                    Text(
                      'Your internship shield is active',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ProtectionStatusCard(
                  status: 'You\'re Protected',
                  message:
                      '${data.scansThisWeek} scans this week from your account.',
                  score: data.scansThisWeek > 0 ? 85 : 50,
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionTitle(title: 'Protection Tools'),
                FeatureTile(
                  title: 'Fake Offer Detector',
                  subtitle: 'Submit real offers for review',
                  icon: LucideIcons.fileWarning,
                  color: AppPalette.crimson,
                  onTap: () => context.push(AppRoutes.offerCheck),
                ),
                const SizedBox(height: AppSpacing.md),
                FeatureTile(
                  title: 'Company Legitimacy',
                  subtitle: 'Search community reports in database',
                  icon: LucideIcons.building2,
                  color: AppPalette.emeraldBright,
                  onTap: () => context.push(AppRoutes.companyVerify),
                ),
                const SizedBox(height: AppSpacing.md),
                FeatureTile(
                  title: 'Data Safety Advisor',
                  subtitle: 'Save privacy check requests',
                  icon: LucideIcons.lock,
                  color: AppPalette.amber,
                  onTap: () => context.push(AppRoutes.dataSafety),
                ),
                const SizedBox(height: AppSpacing.md),
                FeatureTile(
                  title: 'Resume Safety Scanner',
                  subtitle: 'Upload resume for analysis',
                  icon: LucideIcons.fileSearch,
                  color: const Color(0xFF5C6BC0),
                  onTap: () => context.go(AppRoutes.scan),
                ),
                const SizedBox(height: AppSpacing.md),
                FeatureTile(
                  title: 'Blacklist Database',
                  subtitle: 'Global community fraud reports',
                  icon: LucideIcons.ban,
                  color: AppPalette.crimson,
                  onTap: () => context.go(AppRoutes.blacklist),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionTitle(title: 'This Week'),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Scans',
                        value: '${data.scansThisWeek}',
                        icon: LucideIcons.scanLine,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        label: 'Reports Filed',
                        value: '${data.threatsBlocked}',
                        icon: LucideIcons.flag,
                        accentColor: AppPalette.crimson,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionTitle(
                  title: 'Recent Activity',
                  actionLabel: data.recentActivity.isEmpty ? null : 'See all',
                  onAction: data.recentActivity.isEmpty
                      ? null
                      : () => context.push(AppRoutes.history),
                ),
              ],
            ),
          ),
        ),
        if (data.recentActivity.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No activity yet. Run a scan or submit a report.',
                style: context.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = data.recentActivity[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ActivityCard(
                      title: item.title,
                      subtitle: item.subtitle,
                      icon: _iconForType(item.type),
                      color: _colorForType(item.type),
                      time: DateFormat.MMMd().format(item.timestamp),
                    ),
                  );
                },
                childCount: data.recentActivity.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Web Dashboard — 2-column grid layout
// ─────────────────────────────────────────────────────────────────────────────
class _WebDashboardBody extends StatelessWidget {
  const _WebDashboardBody({required this.data});
  final dynamic data;

  IconData _iconForType(String type) => switch (type) {
        'resume' => LucideIcons.fileText,
        'offer' => LucideIcons.fileWarning,
        'company' => LucideIcons.building2,
        _ => LucideIcons.ban,
      };

  Color _colorForType(String type) => switch (type) {
        'resume' => AppPalette.cyberBlue,
        'offer' => AppPalette.crimson,
        'company' => AppPalette.emeraldBright,
        _ => AppPalette.amber,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveLayout.contentMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top greeting + protection status ───────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${data.user.name} 👋',
                        style: context.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your internship shield is active and monitoring.',
                        style: context.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                // Quick stats in top-right
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Scans This Week',
                          value: '${data.scansThisWeek}',
                          icon: LucideIcons.scanLine,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          label: 'Reports Filed',
                          value: '${data.threatsBlocked}',
                          icon: LucideIcons.flag,
                          accentColor: AppPalette.crimson,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Protection status banner ────────────────────────────────────
            ProtectionStatusCard(
              status: 'You\'re Protected',
              message:
                  '${data.scansThisWeek} scans this week from your account. All systems operational.',
              score: data.scansThisWeek > 0 ? 85 : 50,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── 2-column: tools grid + activity feed ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left — Protection Tools Grid
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(title: 'Protection Tools'),
                      const SizedBox(height: AppSpacing.md),
                      // 2×3 grid of feature tiles
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 2.8,
                        children: [
                          _WebFeatureCard(
                            title: 'Fake Offer Detector',
                            subtitle: 'Submit real offers for review',
                            icon: LucideIcons.fileWarning,
                            color: AppPalette.crimson,
                            onTap: () => context.push(AppRoutes.offerCheck),
                          ),
                          _WebFeatureCard(
                            title: 'Company Legitimacy',
                            subtitle: 'Search community reports',
                            icon: LucideIcons.building2,
                            color: AppPalette.emeraldBright,
                            onTap: () => context.push(AppRoutes.companyVerify),
                          ),
                          _WebFeatureCard(
                            title: 'Data Safety Advisor',
                            subtitle: 'Privacy check requests',
                            icon: LucideIcons.lock,
                            color: AppPalette.amber,
                            onTap: () => context.push(AppRoutes.dataSafety),
                          ),
                          _WebFeatureCard(
                            title: 'Resume Scanner',
                            subtitle: 'Upload resume for analysis',
                            icon: LucideIcons.fileSearch,
                            color: const Color(0xFF5C6BC0),
                            onTap: () => context.go(AppRoutes.scan),
                          ),
                          _WebFeatureCard(
                            title: 'Blacklist Database',
                            subtitle: 'Global fraud reports',
                            icon: LucideIcons.ban,
                            color: AppPalette.crimson,
                            onTap: () => context.go(AppRoutes.blacklist),
                          ),
                          _WebFeatureCard(
                            title: 'My Uploads',
                            subtitle: 'View saved files',
                            icon: LucideIcons.folderOpen,
                            color: AppPalette.cyberBlue,
                            onTap: () => context.go(AppRoutes.myUploads),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.xl),

                // Right — Activity Feed
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(
                        title: 'Recent Activity',
                        actionLabel:
                            data.recentActivity.isEmpty ? null : 'See all',
                        onAction: data.recentActivity.isEmpty
                            ? null
                            : () => context.push(AppRoutes.history),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (data.recentActivity.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppPalette.navyElevated.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: isDark
                                  ? AppPalette.slateBorder
                                  : AppPalette.mist,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clipboardList,
                                size: 36,
                                color: context.mutedColor,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No activity yet',
                                style: context.textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Run a scan or submit a report to see activity here.',
                                style: context.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...data.recentActivity.map<Widget>((item) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ActivityCard(
                              title: item.title,
                              subtitle: item.subtitle,
                              icon: _iconForType(item.type),
                              color: _colorForType(item.type),
                              time: DateFormat.MMMd().format(item.timestamp),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web Feature Card (compact grid tile for web)
// ─────────────────────────────────────────────────────────────────────────────
class _WebFeatureCard extends StatefulWidget {
  const _WebFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_WebFeatureCard> createState() => _WebFeatureCardState();
}

class _WebFeatureCardState extends State<_WebFeatureCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _hovering
                ? (isDark
                    ? AppPalette.navyElevated
                    : Colors.white)
                : (isDark
                    ? AppPalette.navySurface.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: _hovering
                  ? widget.color.withValues(alpha: 0.5)
                  : (isDark
                      ? AppPalette.slateBorder.withValues(alpha: 0.6)
                      : AppPalette.mist),
              width: _hovering ? 1.5 : 1,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.2),
                      widget.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: widget.color.withValues(alpha: 0.3)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: context.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: _hovering ? widget.color : context.mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
