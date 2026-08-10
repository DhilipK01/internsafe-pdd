import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/brand/app_palette.dart';
import 'package:internsfe/core/brand/internsafe_brand_title.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/info_card.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';
import 'package:internsfe/presentation/features/shared_report/presentation/shared_report_unavailable_screen.dart';
import 'package:internsfe/presentation/features/shared_report/widgets/shared_document_preview.dart';
import 'package:internsfe/presentation/features/shared_report/widgets/shared_report_analysis_body.dart';

final sharedReportProvider = FutureProvider.family<SharedSnapshot, String>(
  (ref, token) => ref.read(shareRepositoryProvider).getShare(token),
);

/// Premium shared AI report — opened from `/share/:token` deep links.
class SharedReportScreen extends ConsumerWidget {
  const SharedReportScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedReportProvider(token));

    return async.when(
      loading: () => AppScaffold(
        title: 'Shared report',
        showBackToHome: true,
        body: const _SharedReportLoading(),
      ),
      error: (e, _) {
        final msg = e is ApiException
            ? e.message
            : 'This shared report could not be loaded.';
        return SharedReportUnavailableScreen(
          token: token,
          message: msg,
          onRetry: () => ref.invalidate(sharedReportProvider(token)),
        );
      },
      data: (share) => AppScaffold(
        title: 'Shared report',
        showBackToHome: true,
        body: _SharedReportBody(share: share),
      ),
    );
  }
}

class _SharedReportLoading extends StatelessWidget {
  const _SharedReportLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const InternsafeLogo(size: 72, showGlow: true, animate: true),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Loading AI analysis…',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.xxl),
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: context.isDark
                        ? AppColors.cardDark.withValues(alpha: 0.6)
                        : AppPalette.pearl,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedReportBody extends StatelessWidget {
  const _SharedReportBody({required this.share});

  final SharedSnapshot share;

  @override
  Widget build(BuildContext context) {
    final s = share.snapshot;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: InternsafeBrandTitle(compact: true)),
            const SizedBox(height: AppSpacing.lg),
            Text(share.title, style: context.textTheme.headlineMedium),
            if (share.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                share.subtitle!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppPalette.emeraldBright,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SharedByCard(snapshot: s),
            if (share.documentPreviewUrl != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Uploaded content', style: context.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              SharedDocumentPreview(
                previewUrl: share.documentPreviewUrl!,
                fileName: share.document?['fileName'] as String?,
                mimeType: share.document?['mimeType'] as String?,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (!share.hasAnalysis)
              InfoCard(
                child: Text(
                  'This analysis is no longer available or was not completed when shared.',
                  style: context.textTheme.bodyMedium,
                ),
              )
            else
              ...SharedReportAnalysisBody.build(context, share.type, s),
            if (s['sharedAtIst'] != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Shared ${s['sharedAtIst']}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.mutedColor,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            PrimaryButton(
              label: 'Done',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedByCard extends StatelessWidget {
  const _SharedByCard({required this.snapshot});

  final Map<String, dynamic> snapshot;

  @override
  Widget build(BuildContext context) {
    final by = snapshot['sharedBy'] as Map<String, dynamic>?;
    if (by == null) return const SizedBox.shrink();

    final initials = by['initials'] as String? ?? 'IN';
    final name = by['name'] as String? ?? 'INTERNSAFE user';
    final email = by['emailMasked'] as String?;
    final college = by['college'] as String?;
    final verified = by['verified'] == true;

    return InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppPalette.emeraldBright,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.backgroundDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared by',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.mutedColor,
                  ),
                ),
                Text(name, style: context.textTheme.titleSmall),
                if (email != null)
                  Text(email, style: context.textTheme.bodySmall),
                if (college != null && college.isNotEmpty)
                  Text(college, style: context.textTheme.bodySmall),
                if (verified)
                  Text(
                    'Verified member',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
