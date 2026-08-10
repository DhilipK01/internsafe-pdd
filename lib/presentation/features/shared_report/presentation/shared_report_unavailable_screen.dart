import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/brand/internsafe_logo.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/primary_button.dart';

class SharedReportUnavailableScreen extends ConsumerWidget {
  const SharedReportUnavailableScreen({
    super.key,
    this.token,
    this.message,
    this.onRetry,
  });

  final String? token;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const InternsafeLogo(size: 64, showGlow: true),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Shared Report Not Available',
                style: context.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message ??
                    'This shared analysis may have expired, been removed, or the link is invalid.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Go Home',
                onPressed: () => context.go(AppRoutes.home),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
