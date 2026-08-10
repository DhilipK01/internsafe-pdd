import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/utils/debouncer.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/search_field.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BlacklistSearchScreen extends ConsumerStatefulWidget {
  const BlacklistSearchScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  @override
  ConsumerState<BlacklistSearchScreen> createState() =>
      _BlacklistSearchScreenState();
}

class _BlacklistSearchScreenState extends ConsumerState<BlacklistSearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debouncer.run(() => setState(() => _query = value.trim()));
  }

  void _openResult() {
    if (_query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 2 characters to search')),
      );
      return;
    }
    context.push(AppRoutes.blacklistResult, extra: _query);
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = _query.length >= 2
        ? ref.watch(blacklistSearchProvider(_query))
        : const AsyncValue.data(null);

    return AppScaffold(
      title: 'Blacklist',
      showBackToHome: !widget.showBottomNav,
      showBottomNav: widget.showBottomNav,
      bottomNavIndex: 3,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.reportCompany),
          icon: const Icon(LucideIcons.flag),
        ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search real community reports from the database.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SearchField(
              controller: _controller,
              hint: 'Search company name...',
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _openResult(),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Search Blacklist',
              icon: LucideIcons.search,
              onPressed: _openResult,
            ),
            const SizedBox(height: AppSpacing.xl),
            searchAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Search failed: $e'),
              data: (entry) {
                if (_query.length < 2) {
                  return Text(
                    'Type a company name to search.',
                    style: context.textTheme.bodySmall,
                  );
                }
                if (entry == null) {
                  return Text(
                    'No reports found for "$_query".',
                    style: context.textTheme.bodyMedium,
                  );
                }
                return ListTile(
                  title: Text(entry.companyName),
                  subtitle: Text(
                    '${entry.reportCount} reports · danger ${entry.dangerScore}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(blacklistResultProvider.notifier).state = entry;
                    context.push(AppRoutes.blacklistResult);
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.reportCompany),
              icon: const Icon(LucideIcons.flag),
              label: const Text('Report Fake Company'),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
