import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/danger_button.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/report_card.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/core/widgets/share_result_button.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:internsfe/domain/entities/blacklist_entry.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BlacklistResultScreen extends ConsumerWidget {
  const BlacklistResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GoRouterState.of(context).extra as String?;
    final entryFromProvider = ref.watch(blacklistResultProvider);
    final entryAsync = query != null && entryFromProvider == null
        ? ref.watch(blacklistSearchProvider(query))
        : null;

    if (entryAsync != null) {
      return entryAsync.when(
        loading: () => const AppScaffold(
          showBackToHome: true,
          title: 'Loading',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => AppScaffold(
          showBackToHome: true,
          title: 'Error',
          body: Center(child: Text('$e')),
        ),
        data: (entry) {
          if (entry == null) {
            return AppScaffold(
              showBackToHome: true,
              title: 'Not Found',
              body: Center(child: Text('No reports for "$query"')),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(blacklistResultProvider.notifier).state = entry;
          });
          return _BlacklistResultBody(entry: entry);
        },
      );
    }

    final entry = entryFromProvider;
    if (entry == null) {
      return const AppScaffold(
        showBackToHome: true,
        title: 'Result',
        body: Center(child: Text('No result loaded')),
      );
    }
    return _BlacklistResultBody(entry: entry);
  }
}

class _BlacklistResultBody extends StatelessWidget {
  const _BlacklistResultBody({required this.entry});

  final BlacklistEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: entry.companyName,
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: AppColors.dangerRed.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.alertOctagon,
                    color: AppColors.dangerRed,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'DO NOT APPLY',
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('Danger Score: ${entry.dangerScore}/100'),
                  Text('${entry.reportCount} community reports'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Fraud types reported'),
            Wrap(
              spacing: AppSpacing.sm,
              children: entry.fraudTypes.map((t) => Chip(label: Text(t))).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (entry.recentReport.isNotEmpty)
              InfoCard(child: Text(entry.recentReport)),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Community reports'),
            ...entry.reports.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ReportCard(
                  companyName: entry.companyName,
                  reportType: r.reportType,
                  date: r.date,
                  college: r.college,
                ),
              ),
            ),
            ShareResultButton(
              resourceType: ShareResourceType.blacklist,
              query: entry.companyName,
            ),
            const SizedBox(height: AppSpacing.lg),
            DangerButton(
              label: 'Report This Company',
              icon: LucideIcons.flag,
              onPressed: () => context.push(AppRoutes.reportCompany),
            ),
          ],
        ),
      ),
    );
  }
}
