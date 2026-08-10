import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/domain/entities/data_safety_result.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DataSafetyResultScreen extends ConsumerWidget {
  const DataSafetyResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(dataSafetyResultProvider);
    if (result == null) {
      return const AppScaffold(
        showBackToHome: true,
        title: 'Results',
        body: Center(child: Text('No analysis found')),
      );
    }

    return AppScaffold(
      title: 'Data Safety Guidance',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stage: ${result.stage}',
                        style: context.textTheme.titleMedium),
                    if (result.analyzedAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Analyzed: ${result.analyzedAt}',
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: context.mutedColor),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(result.summary),
                    if (result.nextAction != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Next: ${result.nextAction}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _WarningBanner(warnings: result.warnings),
            ],
            const SizedBox(height: AppSpacing.lg),
            _CategorySection(
              title: 'Safe to share now',
              icon: LucideIcons.shieldCheck,
              color: Colors.green.shade700,
              items: result.byCategory(DataSafetyCategory.safeNow),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategorySection(
              title: 'Share later',
              icon: LucideIcons.clock,
              color: Colors.orange.shade800,
              items: result.byCategory(DataSafetyCategory.shareLater),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategorySection(
              title: 'Never share early',
              icon: LucideIcons.shieldAlert,
              color: Colors.red.shade700,
              items: result.byCategory(DataSafetyCategory.neverShare),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: Colors.red.shade800),
                const SizedBox(width: AppSpacing.sm),
                Text('Warnings', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('• $w'),
                )),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<DataSafetyItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Text(item.label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.explanation.isNotEmpty) Text(item.explanation),
                  if (item.whenSafe != null && item.whenSafe!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('When safe: ${item.whenSafe}'),
                    ),
                  if (item.saferAlternative != null &&
                      item.saferAlternative!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text('Alternative: ${item.saferAlternative}'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
