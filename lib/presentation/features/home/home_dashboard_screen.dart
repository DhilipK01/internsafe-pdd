import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/glass_surface.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
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
        data: (data) => CustomScrollView(
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
        ),
      ),
      ),
    );
  }

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
}
