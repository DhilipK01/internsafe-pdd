import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_colors.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/utils/debouncer.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/search_field.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VerifyCompanyScreen extends ConsumerStatefulWidget {
  const VerifyCompanyScreen({super.key, this.showBottomNav = false});

  final bool showBottomNav;

  @override
  ConsumerState<VerifyCompanyScreen> createState() =>
      _VerifyCompanyScreenState();
}

class _VerifyCompanyScreenState extends ConsumerState<VerifyCompanyScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  String _suggestQuery = '';
  bool _loading = false;
  String _loadingPhase = '';

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a company name')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _loadingPhase = 'Searching public web reputation…';
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        setState(() => _loadingPhase = 'Checking community intelligence…');
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        setState(() => _loadingPhase = 'Analyzing reputation & generating insights…');
      }
      final result =
          await ref.read(companyRepositoryProvider).verifyCompany(name);
      ref.read(companyResultProvider.notifier).state = result;
      if (!mounted) return;
      if (result.reportCount > 0) {
        context.push(AppRoutes.companySuspicious);
      } else {
        context.push(AppRoutes.companyVerified);
      }
    } catch (e) {
      String msg;
      if (e is DioException && e.error is ApiException) {
        final apiMsg = (e.error as ApiException).message;
        if (apiMsg.contains('timed out') || apiMsg.contains('Check your network')) {
          msg =
              'Verification is taking longer than expected. Please try again — '
              'community data may still be available on retry.';
        } else if (apiMsg.contains('Cannot reach server')) {
          msg =
              'Unable to reach INTERNSAFE servers. Check API_BASE_URL and try again.';
        } else {
          msg = apiMsg;
        }
      } else {
        msg = 'Verification could not be completed. Please try again.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingPhase = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestQuery.length >= 2
        ? ref.watch(companySearchProvider(_suggestQuery))
        : const AsyncValue.data(<String>[]);

    return AppScaffold(
      title: 'Company Verifier',
      showBackToHome: !widget.showBottomNav,
      showBottomNav: widget.showBottomNav,
      bottomNavIndex: 2,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AI-powered reputation engine: community reports, public web intelligence, and dynamic trust scoring.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SearchField(
              controller: _controller,
              hint: 'Company name',
              onChanged: (v) => _debouncer.run(() => setState(() => _suggestQuery = v.trim())),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading && _loadingPhase.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _loadingPhase,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: AppColors.primaryGreen,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Verify Company',
              icon: LucideIcons.badgeCheck,
              isLoading: _loading,
              onPressed: _verify,
            ),
            const SizedBox(height: AppSpacing.lg),
            suggestions.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suggestions', style: context.textTheme.titleMedium),
                    ...list.map(
                      (c) => ListTile(
                        title: Text(c),
                        onTap: () {
                          _controller.text = c;
                          _verify();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
